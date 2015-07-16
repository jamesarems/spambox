package rebuildspamdb; # RBEOT;

our $VERSION = '7.11';

rb_mlog("info: rebuildspamdb module version ".${'VERSION'}." loaded");

# rebuildspamdb version 2
# rebuilds bayesian spam and HMM database
# (c) John Hanna 2003 under the terms of the GPL
# Updated July 2004 for simple proxy support.
# (c) Fritz Borgstedt 2006 under the terms of the GPL
# Updated Feb 2008 refactoring and rewrites
# (c) Kevin 2008 under the terms of the GPL
# Updated Jul 2008 refactoring and rewrites to build in as package in SPAMBOX
# and integrated move2num
# (c) Thomas Eckardt since 2008 under the terms of the GPL

use strict qw(vars subs);
use Digest::MD5 qw(md5_hex);
use File::Copy;
use IO::Handle;
use IO::Socket();
use Encode;
use Storable();
no warnings;

our $RebuildLog;
our $RebuildDebug;
our $norm;
our $starttime;
our $processTime;
our $processedBytes;
our $scanTime;
our $scanFiles;
our %spam; keys %spam = $main::MaxFiles * 20;
our %newspam; keys %newspam = $main::MaxFiles * 20;
our %Helo; keys %Helo = $main::MaxFiles;
our %HamHash; keys %HamHash = $main::MaxFiles;
our %SpamHash; keys %SpamHash = $main::MaxFiles;
our %HMMres;
our %GpCnt;
our %GpOK;
our %Trashlist;
our $spamObj;
our $newspamObj;
our $HeloObj;
our $HamHashObj;
our $HMMresObj;
our $SpamHashObj;
our $GpCntObj;
our $GpOKObj;
our $TrashlistObj;
our $SpamWordCount;
our $HamWordCount;
our $Iam;
our $BDBEnv;
our $DBDir;
our $WhiteCount;
our $RedCount;
our $onlyNewCorrected;
our $IPRe = $main::IPRe;
our $spamHMM;
our $hamHMM;
our $DoHMM;
our $attachments;
our $rtText;
our $mintime;
our $movetime;
our $doattach;
our $CanUseUnicodeNormalize = $main::CanUseUnicodeNormalize && require Unicode::Normalize;

sub rb_run {         ## no critic
no warnings;
$onlyNewCorrected = shift;

$SpamWordCount = 0;
$HamWordCount = 0;
$processedBytes = 0;
$starttime = 0;
$processTime = 0;
$processedBytes = 0;
$scanTime = 0;
$scanFiles = 0;

$WhiteCount = 0;
$RedCount = 0;
$attachments = 0;

$DoHMM = $main::DoHMM;
$doattach = 0;
$doattach = 1 if    $main::Config{SPAMBOX_AFCDetectSpamAttachRe}
                 && $main::SPAMBOX_AFCDetectSpamAttachReRE !~ $main::neverMatchRE;
($mintime,$movetime) = split(/(?:\s+|,)/o,$main::RebuildFileTimeLimit,2);
$mintime =~ s/\s//go;
$movetime =~ s/\s//go;
$mintime ||= 0;
$movetime ||= 0;

$RebuildDebug = -e "$main::base/rebuilddebug.txt";
$RebuildDebug = 0 if $onlyNewCorrected;
my (@dbhint, $have_error);

if ($RebuildDebug) {
    open($RebuildDebug ,'>',  "$main::base/rebuilddebug.txt" );
    binmode $RebuildDebug;
    $RebuildDebug->autoflush;
    rb_mlog("rebuild debug output is enabled to $main::base/rebuilddebug.txt");
    push @dbhint , "-rebuild debug output is enabled to $main::base/rebuilddebug.txt";
}

eval (<<'EOT') if ($main::CanUseSPAMBOX_WordStem);
    use SPAMBOX_WordStem();
    $SPAMBOX_WordStem::logging = 0;
EOT

    if ($main::canUnicode && $^O eq 'MSwin32') {require Win32::Unicode;}
    $DBDir = "$main::base/tmpDB/rebuildDB";
    $Iam = $main::WorkerNumber;
    -d $DBDir or mkdir $DBDir,0755;

    if ($main::CanUseBerkeleyDB && $main::useDB4Rebuild) {
        eval('use BerkeleyDB;');
        if ($main::VerBerkeley lt '0.42') {
            *{'BerkeleyDB::_tiedHash::CLEAR'} = *{'main::BDB_CLEAR'};
        }
        my $cachesize;
        for (&main::Glob("$DBDir/*.bdb")) { $cachesize += -s $_ }
        $cachesize = &main::min($main::BDBMaxCacheSize, 200*1024*1024, &main::max($cachesize,($DoHMM ? 41943040 : 20971520)));
        rb_mlog("RebuildSpamDB uses BerkeleyDB for temporary hashes");
        push @dbhint , "-RebuildSpamDB uses BerkeleyDB for temporary hashes";
        rb_mlog("RebuildSpamDB uses BerkeleyDB-ENV with ".&main::formatNumDataSize(int($cachesize * 1.25)));
        push @dbhint , "-RebuildSpamDB uses BerkeleyDB-ENV with ".&main::formatNumDataSize(int($cachesize * 1.25));
        unlink "$DBDir/__db.001";
        unlink "$DBDir/__db.002";
        unlink "$DBDir/__db.003";
        unlink "$DBDir/BDB-error.txt";
        if (! $onlyNewCorrected) {
            unlink "$DBDir/rb_spam.bdb";
            unlink "$DBDir/rb_Helo.bdb";
        }
eval (<<'EOT');
            $main::lastd{$Iam} = "building BerkeleyDB ENV";
            $BDBEnv = BerkeleyDB::Env->new(-Flags => DB_CREATE | DB_INIT_MPOOL,
                                           -Cachesize => $cachesize ,
                                           -Home    => "$DBDir",
                                           -ErrFile => "$DBDir/BDB-error.txt" ,
                                           -Config  => {DB_DATA_DIR => "$DBDir",
                                                        DB_LOG_DIR  => "$DBDir",
                                                        DB_TMP_DIR  => "$DBDir"}
                                          );
            die("can't create BDB-ENV for rebuild - see $DBDir/BDB-error.txt\n") if (! $BDBEnv || $BerkeleyDB::Error !~ /: 0\s*$/o);

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_spam.bdb";
            $spamObj=tie %spam,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_spam.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);
            rb_BDB_getRecordCount('spam');

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_newspam.bdb";
            $newspamObj=tie %newspam,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_newspam.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_Helo.bdb";
            $HeloObj=tie %Helo,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_Helo.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);
            rb_BDB_getRecordCount('Helo');

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_HamHash.bdb";
            $HamHashObj=tie %HamHash,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_HamHash.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_SpamHash.bdb";
            $SpamHashObj=tie %SpamHash,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_SpamHash.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_GpCnt.bdb";
            $GpCntObj=tie %GpCnt,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_GpCnt.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_GpOK.bdb";
            $GpOKObj=tie %GpOK,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_GpOK.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/trashlist.bdb";
            $TrashlistObj=tie %Trashlist,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/trashlist.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);
            rb_BDB_getRecordCount('Trashlist') == 0 && rb_Load_Trashlist();

            $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rb_HMMres.bdb";
            $HMMresObj=tie %HMMres,'BerkeleyDB::Hash',
                                     (-Filename => "$DBDir/rb_HMMres.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $BDBEnv);
EOT
            if ($@ or $BerkeleyDB::Error !~ /: 0\s*$/o) {
                rb_mlog("BerkeleyDB-ERROR: in $main::lastd{$Iam} - $@ - BDB:$BerkeleyDB::Error");
                push @dbhint , "-BerkeleyDB-ERROR: in $main::lastd{$Iam} - $@ - BDB:$BerkeleyDB::Error";
                $have_error = 1;
            }
    } elsif ($main::CanUseDB_File && $main::useDB4Rebuild) {
        eval('use DB_File;');
        rb_mlog("RebuildSpamDB uses DB_File for temporary hashes");
eval (<<'EOT');
        $spamObj = tie %spam, 'DB_File', "$DBDir/rb_spam.bdb";
        $newspamObj = tie %newspam, 'DB_File', "$DBDir/rb_newspam.bdb";
        $HeloObj = tie %Helo, 'DB_File', "$DBDir/rb_Helo.bdb";
        $HamHashObj = tie %HamHash, 'DB_File', "$DBDir/rb_HamHash.bdb";
        $SpamHashObj = tie %SpamHash, 'DB_File', "$DBDir/rb_SpamHash.bdb";
        $GpCntObj = tie %GpCnt, 'DB_File', "$DBDir/rb_GpCnt.bdb";
        $GpOKObj = tie %GpOK, 'DB_File', "$DBDir/rb_GpOK.bdb";
        $TrashlistObj = tie %Trashlist,'DB_File', "$DBDir/trashlist.bdb";
        scalar(keys %Trashlist) == 0 && rb_Load_Trashlist();
EOT
        if ($@) {
            rb_mlog("DB_File-ERROR: $@");
            push @dbhint , "-DB_File-ERROR: $@";
            $have_error = 1;
        }
    } elsif ($main::useDB4Rebuild) {
        rb_mlog("RebuildSpamDB uses the internal 'orderedtie' for temporary hashes");
        push @dbhint , "warning: 'useDB4Rebuild' is set to on, but 'BerkeleyDB' nor 'DB_File' are available - the rebuild spamdb process uses the internal 'orderedtie' and will possibly require more time and a large amount of memory - check 'OrderedTieHashTableSize'!";
eval (<<'EOT');
        $spamObj = tie %spam, 'orderedtie', "$DBDir/rb_spam.bdb";
        $newspamObj = tie %newspam, 'orderedtie', "$DBDir/rb_newspam.bdb";
        $HeloObj = tie %Helo, 'orderedtie', "$DBDir/rb_Helo.bdb";
        $HamHashObj = tie %HamHash, 'orderedtie', "$DBDir/rb_HamHash.bdb";
        $SpamHashObj = tie %SpamHash, 'orderedtie', "$DBDir/rb_SpamHash.bdb";
        $GpCntObj = tie %GpCnt, 'orderedtie', "$DBDir/rb_GpCnt.bdb";
        $GpOKObj = tie %GpOK, 'orderedtie', "$DBDir/rb_GpOK.bdb";
        $TrashlistObj = tie %Trashlist,'orderedtie', "$DBDir/trashlist.bdb";
EOT
        if ($@) {
            push @dbhint , "-orderedtie-ERROR: $@";
            rb_mlog("orderedtie-ERROR: $@");
            $have_error = 1;
        }
    } else {
        $TrashlistObj = tie %Trashlist,'orderedtie', "$main::base/trashlist.db";
        push @dbhint , "warning: 'useDB4Rebuild' is NOT set to on - the rebuild spamdb process will possibly require a very large amount of memory - but it will run very fast!";
    }

    if ($DoHMM && $main::CanUseBerkeleyDB && $main::useDB4Rebuild) {
        if (! $onlyNewCorrected) {
            unlink "$DBDir/rbtmp.hamHMM.bdb";
            unlink "$DBDir/rbtmp.spamHMM.bdb";
            unlink "$DBDir/rbtmp.hamHMM.totals.bdb";
            unlink "$DBDir/rbtmp.spamHMM.totals.bdb";
        }
        if ($onlyNewCorrected ||
           (   ! $onlyNewCorrected
            && ! -e "$DBDir/rbtmp.hamHMM.bdb"
            && ! -e "$DBDir/rbtmp.spamHMM.bdb"
            && ! -e "$DBDir/rbtmp.hamHMM.totals.bdb"
            && ! -e "$DBDir/rbtmp.spamHMM.totals.bdb"))
        {
            $@ = '';
            eval (<<'EOT');
                $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rbtmp.hamHMM";
                $hamHMM  = SPAMBOX::MarkovChain->new(longest => $main::HMMSequenceLength,
                                                  shortest => $main::HMMSequenceLength,
                                                  top => 1,
                                                  nostarts => 1,
                                                  BDB => {-Filename => "$DBDir/rbtmp.hamHMM" ,
                                                          -Flags => DB_CREATE
                                                          -Env => $BDBEnv}
                                                  );
                $main::lastd{$Iam} = "mounting BerkeleyDB $DBDir/rbtmp.spamHMM";
                $spamHMM = SPAMBOX::MarkovChain->new(longest => $main::HMMSequenceLength,
                                                  shortest => $main::HMMSequenceLength,
                                                  top => 1,
                                                  nostarts => 1,
                                                  BDB => {-Filename => "$DBDir/rbtmp.spamHMM" ,
                                                          -Flags => DB_CREATE
                                                          -Env => $BDBEnv}
                                                  ) if ref $hamHMM;
EOT
            unless (ref $hamHMM && ref $spamHMM) {
                my $error;
                $error =  " - e: $@" if $@;
                $error .= " - h: $hamHMM" if $hamHMM && ! ref $hamHMM;
                $error .= " - s: $spamHMM" if $spamHMM && ! ref $spamHMM;
                push @dbhint , "error: can't create HMM because of BDB database errors ($DBDir) - $error";
                $DoHMM = 0 ;
                $hamHMM = undef;
                $spamHMM = undef;
            }
        } else {
            push @dbhint , "error: can't cleanup at least one old temporary BDB file used for HMM in $DBDir/ 'rbtmp.hamHMM.bdb , rbtmp.spamHMM.bdb , rbtmp.hamHMM.totals.bdb, rbtmp.spamHMM.totals.bdb'";
        }
        unless (ref $hamHMM && ref $spamHMM) {
            $DoHMM = 0 ;
            $hamHMM = undef;
            $spamHMM = undef;
        }
    } else {
        if ($DoHMM) {
            if (! $onlyNewCorrected) {
                unlink "$DBDir/rbtmp.hamHMM.chains";
                unlink "$DBDir/rbtmp.spamHMM.chains";
                unlink "$DBDir/rbtmp.hamHMM.totals";
                unlink "$DBDir/rbtmp.spamHMM.totals";
            }
            $@ = '';
            eval (<<'EOT');
                $main::lastd{$Iam} = "loading model from $DBDir/rbtmp.hamHMM in to memory";
                $hamHMM  = SPAMBOX::MarkovChain->new(longest => $main::HMMSequenceLength,
                                                  shortest => $main::HMMSequenceLength,
                                                  top => 1,
                                                  nostarts => 1,
                                                  File => "$DBDir/rbtmp.hamHMM" ,
                                                  );
                $main::lastd{$Iam} = "loading model from $DBDir/rbtmp.spamHMM in to memory";
                $spamHMM = SPAMBOX::MarkovChain->new(longest => $main::HMMSequenceLength,
                                                  shortest => $main::HMMSequenceLength,
                                                  top => 1,
                                                  nostarts => 1,
                                                  File => "$DBDir/rbtmp.spamHMM" ,
                                                  ) if ref $hamHMM;
EOT
            unless (ref $hamHMM && ref $spamHMM) {
                my $error;
                $error =  " - e: $@" if $@;
                $error .= " - h: $hamHMM" if $hamHMM && ! ref $hamHMM;
                $error .= " - s: $spamHMM" if $spamHMM && ! ref $spamHMM;
                push @dbhint , "error: can't create HMM because of Storable errors ($DBDir) - $error";
                $DoHMM = 0 ;
                $hamHMM = undef;
                $spamHMM = undef;
            }
        }
    }

    # reset counts and global vars
    $HamWordCount = $SpamWordCount = my $correctedspamcount = 0;
    my $correctednotspamcount = my $spamlogcount  = my $notspamlogcount = 0;
    my $rebuildrun = &rb_fixPath($main::base) . "/rebuildrun.txt";

    $RebuildLog = $norm = $starttime = $processTime = '';

    if ($onlyNewCorrected && ! $have_error) {         # only still new reported
        my ($havenormfile,$SwordsPfile, $HwordsPfile);
        if (open( my $normFile, '<', "$main::base/normfile" )) {
            binmode $normFile;
            ($norm, $correctedspamcount, $correctednotspamcount, $spamlogcount, $notspamlogcount,
             $SwordsPfile, $HwordsPfile, $SpamWordCount, $HamWordCount) = split(/\s+/o, join('',<$normFile>));
            $havenormfile = $SpamWordCount > 0 || $HamWordCount > 0;
            close $normFile;
        }
        $norm ||= $main::bayesnorm || $main::Spamdb{'***bayesnorm***'};
        $norm ||= $main::HMMdb{'***bayesnorm***'} if $DoHMM;
        $norm ||= 1;
        my $oldnorm = $norm;

        rb_processNewCorrected();

        if ($havenormfile) {
            $main::bayesnorm = $main::Spamdb{'***bayesnorm***'} = $norm = $HamWordCount ? ( $SpamWordCount / $HamWordCount ) : 100;
            $main::HMMdb{'***bayesnorm***'} = $norm if $DoHMM;
            &rb_mlog("info: the corpus norm is changed from: $oldnorm - to: $norm") if $oldnorm != $norm;
            (open( my $normFile, '>', "$main::base/normfile" ));
            if ($normFile) {
                print { $normFile } "$norm $correctedspamcount $correctednotspamcount $spamlogcount $notspamlogcount $SwordsPfile $HwordsPfile $SpamWordCount $HamWordCount";
                eval{close $normFile;};
            }
        }
    } elsif (! $have_error) {                         # the normal rebuild

    %spam = ();
    %newspam = ();
    %Helo = ();
    %HamHash = ();
    %SpamHash = ();
    %GpCnt = ();
    %GpOK = ();
    %HMMres = ();

    # open log file
    if ( -e "$rebuildrun.bak" ) {
        unlink("$rebuildrun.bak") or die "unable to remove file: $!";
    }
    if ( -e $rebuildrun ) {
        copy( $rebuildrun, "$rebuildrun.bak" ) or die "unable to copy file for: $!";
    }
    (open( $RebuildLog, '>', "$rebuildrun" )) or die "unable to open file for logging: $!";
    binmode $RebuildLog;
    $RebuildLog->autoflush;
    $starttime = time;
    &rb_printlog( "\n\n\nRebuildSpamDB-thread rebuildspamdb-version ".${'VERSION'}." started in SPAMBOX version $main::version$main::modversion\n" );
    &rb_mlog( "RebuildSpamDB-thread rebuildspamdb-version ".${'VERSION'}." started in SPAMBOX version $main::version$main::modversion");
    while (@dbhint) {
        my $t = shift @dbhint;
        &rb_mlog( $t ) unless $t =~ s/^\-//o;
        &rb_printlog( "\n$t\n" );
    }
    if ($main::RebuildTestMode) {
        &rb_printlog( "\n***** RebuildSpamDB is running in TEST MODE *****\n" );
        &rb_mlog( "***** RebuildSpamDB is running in TEST MODE *****" );
    }
    if ($DoHMM) {
        &rb_printlog( "\nRebuildSpamDB will create a Hidden Markov Model\n" );
        &rb_mlog( "RebuildSpamDB will create a Hidden Markov Model" );
    } else {
        &rb_printlog( "\nRebuildSpamDB will NOT create a Hidden Markov Model\n" );
        &rb_mlog( "RebuildSpamDB will NOT create a Hidden Markov Model" );
    }
    if ($doattach) {
        &rb_printlog( "\nRebuildSpamDB will include attachment-database-entries in to spamdb\n" );
        &rb_mlog( "RebuildSpamDB will include attachment-database-entries in to spamdb" );
    }
    if ($main::canUnicode) {
        &rb_printlog( "\nRebuildSpamDB will create unicode enabled databases\n" );
        &rb_mlog( "RebuildSpamDB will create unicode enabled databases" );
    }
    if ($main::CanUseUnicodeGCString) {
        &rb_printlog( "\nRebuildSpamDB will process all words as Sequence of UAX #29 Grapheme Clusters\n" );
        &rb_mlog( "RebuildSpamDB will process all words as Sequence of UAX #29 Grapheme Clusters" );
    }
    if ($main::normalizeUnicode && $CanUseUnicodeNormalize) {
        &rb_printlog( "\nRebuildSpamDB will normalize unicode characters\n" );
        &rb_mlog( "RebuildSpamDB will normalize unicode characters" );
    }
    if ($main::CanUseSPAMBOX_WordStem) {
        &rb_printlog( "\nRebuildSpamDB will use the SPAMBOX_WordStem engine\n" );
        &rb_mlog( "RebuildSpamDB will use the SPAMBOX_WordStem engine" );
    }
    &rb_printlog("\n---SPAMBOX Settings---\n");
    if ($main::DoPrivatSpamdb) {
        my $text = ($main::DoPrivatSpamdb == 1) ? 'users email addresses only.'
                 : ($main::DoPrivatSpamdb == 2) ? 'each local domain.'
                 : 'users email addresses and each local domain.';
        &rb_printlog("\nRebuildSpamDB will create private spamdb entries for $text\n\n");
        &rb_mlog("RebuildSpamDB will create private spamdb entries for $text.");
    }
    if ($main::DoNotCollectRedList) {
        &rb_printlog(
            "Do Not Collect Messages with RedListed address: Enabled\n**Messages with RedListed addresses will be removed from the corpus!**\n\n"
          );
    }
    if ($main::DoNotCollectRedRe) {
        &rb_printlog(
            "Do Not Collect RedRe Messages: Enabled\n**Messages matching the RedRe will be removed from the corpus!**\n\n");
    }
    if ($main::UseSubjectsAsMaillogNames) {
        &rb_printlog("Use Subject as Maillog Names: True\n");
    } else {
        &rb_printlog("Use Subject as Maillog Names: False\n");
    }
    &rb_printlog("Maxbytes: ".&rb_commify($main::MaxBytes)." \n");
    &rb_mlog("Maxfiles: ".&rb_commify($main::MaxFiles));

    &rb_printlog("RebuildFileTimeLimit: $main::RebuildFileTimeLimit \n");
    &rb_mlog("RebuildFileTimeLimit: $main::RebuildFileTimeLimit");

    if ($movetime) {
        &rb_printlog("RebuildFileTimeLimit: files will be moved away from the corpus if their processing takes longer than $movetime second(s) \n");
        &rb_mlog("RebuildFileTimeLimit: files will be moved away from the corpus if their processing takes longer than $movetime second(s)");
    }

    #cleanup deleted files
    &rb_cleanTrashlist();

    # start move2num to normalize filenames
    &rb_move2num() if $main::doMove2Num;

    # isspam?, path, filter, weight, processing sub
    $correctedspamcount    = &rb_processfolder( 1, $main::correctedspam,    "*", 2, \&rb_dospamhash );
    $correctednotspamcount = &rb_processfolder( 0, $main::correctednotspam, "*", 4, \&rb_dohamhash );
    my $tempnorm = ($HamWordCount ? ( $SpamWordCount / $HamWordCount ) : $SpamWordCount ? 9.9999 : 1) || 0.0001;
    my ($neededspam,$neededham, $spamf, $hamf, $SwordsPfile, $HwordsPfile);
    my @tn = split(/\-/o,$main::autoCorrectCorpus);
    my $targetNorm = sprintf("%.3f",(($tn[0] + $tn[1])/2));
    my $nspam = undef;
    if ($tempnorm < 30 && $targetNorm > 0) {
        my $tn = sprintf("%.3f",$tempnorm);
        if ($tempnorm >= 10) {
            &rb_printlog("warning: corpusnorm after processing $main::correctedspam and $main::correctednotspam is very unbalanced (>=10) Spam Weight: $SpamWordCount / Not-Spam Weight: $HamWordCount => norm: $tn  - you should fill some known good files in to the folder $main::correctednotspam\n");
            &rb_mlog("warning: corpusnorm after processing $main::correctedspam and $main::correctednotspam is very unbalanced (>=10) spamwords $SpamWordCount/ hamwords $HamWordCount => $tn - you should fill some known good files in to the folder $main::correctednotspam");
        }
        my @t;
        if (open (my $F, '<', "$main::base/normfile")) {
            binmode $F;
            @t = split(/ /,join('',<$F>));
            close $F;
        }
        if ($t[5] > 0 && $t[6] > 0) {
            $SwordsPfile = $t[5];
            $HwordsPfile = $t[6];

            if ($tempnorm < 10) {
                &rb_printlog("info: corpusnorm after processing $main::correctedspam and $main::correctednotspam is Spam Weight: $SpamWordCount / Not-Spam Weight: $HamWordCount => norm: $tn \n");
                &rb_mlog("info: corpusnorm after processing $main::correctedspam and $main::correctednotspam is spamwords $SpamWordCount/ hamwords $HamWordCount => $tn");
            }
            $spamf = &main::min($main::MaxFiles,&rb_countfiles(&rb_fixPath($main::base.'/'.$main::spamlog).'/'));
            $hamf =  &main::min($main::MaxFiles,&rb_countfiles(&rb_fixPath($main::base.'/'.$main::notspamlog).'/'));
            my $r = ($spamf>0 || $hamf>0) & defined(*{'main::yield'})?$targetNorm:0;

            my $sf = ($HamWordCount - $SpamWordCount + $HwordsPfile * $hamf)/$SwordsPfile;
            &rb_d("spamfiles -> $sf = ($HamWordCount - $SpamWordCount + $HwordsPfile * $hamf)/$SwordsPfile \n");
#            my $f = (($sf * 0.9) > $spamf) ? 1 : 0.9;
            my $f = 1;
            rb_d("info: f = $f , sf = $sf , spamf = $spamf");
            $f = $f / (($main::bayesnorm - $targetNorm + 1) ** 2) if ($main::bayesnorm >= $tn[0] && $main::bayesnorm <= $tn[1]);
            $sf = &main::min($spamf,$sf);
            rb_d("info: SpamCountNormCorrection = $main::SpamCountNormCorrection , f = $f , sf = $sf , spamf = $spamf, norm = $main::bayesnorm, target = $targetNorm");
            $neededspam = int($sf*$r*$f);
            $neededspam = 1 if $neededspam <= 0;
            my $t = ($neededspam < $spamf) ? 'approx. '.&rb_commify($neededspam) : 'approx. all';
            $nspam = int($sf * $r * $SwordsPfile * (1+(($main::SpamCountNormCorrection > -100 && $main::SpamCountNormCorrection < 100) ? $main::SpamCountNormCorrection/100 : 0)));
            $nspam = 2 if $nspam < 2;

            &rb_printlog("info: require $t files (".&rb_commify($nspam)." words".($main::SpamCountNormCorrection ? " +[$main::SpamCountNormCorrection\% included]" : '').") from folder $main::spamlog to get the wanted corpusnorm ($targetNorm)\n");
            &rb_mlog("info: require $t files (".&rb_commify($nspam)." words".($main::SpamCountNormCorrection ? " +[$main::SpamCountNormCorrection\% included]" : '').") from folder $main::spamlog to get the wanted corpusnorm ($targetNorm)");
            $nspam += $SpamWordCount;
        } else {
            &rb_printlog("warning: missing information for automatic corpus correction in file $main::base/normfile.  If this is the first time you have seen this warning, rerun the rebuild!\n");
            &rb_mlog("warning: missing information for automatic corpus correction in file $main::base/normfile.  If this is the first time you have seen this warning, rerun the rebuild!");
        }
    } elsif ($targetNorm > 0) {
        my $tn = sprintf("%.3f",$tempnorm);
        &rb_printlog("warning: corpusnorm after processing $main::correctedspam and $main::correctednotspam is too unbalanced (>=30) Spam Weight: $SpamWordCount / Not-Spam Weight: $HamWordCount => norm: $tn - you should fill some known good files in to the folder $main::correctednotspam\n");
        &rb_mlog("warning: corpusnorm after processing $main::correctedspam and $main::correctednotspam is too unbalanced (>=30) spamwords $SpamWordCount/ hamwords $HamWordCount => $tn - you should fill some known good files in to the folder $main::correctednotspam");
    }
    my $spamWords = $SpamWordCount;
    $spamlogcount = &rb_processfolder( 1, $main::spamlog, "*", 1, \&rb_checkspam , $neededspam, undef, $nspam );
    $spamWords = $SpamWordCount - $spamWords;
    $SwordsPfile = ($SwordsPfile ? int(($SwordsPfile + $spamWords/$spamlogcount)/2) : int($spamWords/$spamlogcount)) if $spamlogcount;
    my $nham = undef;
    if ($neededspam && $targetNorm > 0) {
        $nham = ($SpamWordCount - $HamWordCount)/$targetNorm;
        &rb_d("$nham = ($SpamWordCount - $HamWordCount)/$targetNorm \n");
        $neededham = int($nham/$HwordsPfile);
        &rb_d("$neededham = int($nham/$HwordsPfile) \n");
        $neededham = 1 if $neededham <= 0;
        $nham = 2 if $nham < 2;
        my $t = ($neededham < $hamf) ? "approx. ".&rb_commify($neededham) : 'approx. all';
        &rb_printlog("info: require $t files (".&rb_commify($nham)." words) from folder $main::notspamlog to get the wanted corpusnorm ($targetNorm)\n");
        &rb_mlog("info: require $t files (".&rb_commify($nham)." words) from folder $main::notspamlog to get the wanted corpusnorm ($targetNorm)");
        $nham = (($SpamWordCount/$targetNorm) > $HamWordCount) ? int($SpamWordCount/$targetNorm) : 1;
        &rb_d("$nham = (($SpamWordCount/$targetNorm) > $HamWordCount) ? int($SpamWordCount/$targetNorm) : 1 \n");
    }
    my $hamWords = $HamWordCount;
    $notspamlogcount = &rb_processfolder( 0, $main::notspamlog, "*", 1, \&rb_checkham , $neededham, $nham);
    $hamWords = $HamWordCount - $hamWords;
    $HwordsPfile = ($HwordsPfile ? int(($HwordsPfile + $hamWords/$notspamlogcount)/2) : int($hamWords/$notspamlogcount)) if $notspamlogcount;

    $norm = $HamWordCount ? ( $SpamWordCount / $HamWordCount ) : 100;
    (open( my $normFile, '>', "$main::base/normfile" )) || warn "unable to open $main::base/normfile: $!\n";
    if ($normFile) {
        print { $normFile } "$norm $correctedspamcount $correctednotspamcount $spamlogcount $notspamlogcount $SwordsPfile $HwordsPfile $SpamWordCount $HamWordCount";
        eval{close $normFile;};
    }

    # Create Bayesian DB
    &rb_generatescores();

    # Create HMM DB
    &rb_generateHMM() if $DoHMM;

    # Create HELO blacklist
    &rb_createheloblacklist();

    $main::bayesnorm = $main::Spamdb{'***bayesnorm***'} = $norm;

    &rb_printlog("\nSpam Weight:\t   " . &rb_commify($SpamWordCount) . "\n");
    &rb_printlog("Not-Spam Weight:   " . &rb_commify($HamWordCount) . "\n\n" );
    if ( !($norm) ) {    #invalid norm
        &rb_printlog("Warning: Corpus insufficient to calculate normality!\n");
        &rb_mlog("Warning: Corpus insufficient to calculate normality!");
    }
    else {               #norm exists, print it
        my $normdesc;
        if    ( $norm < 0.6 )   { $normdesc = '(warning: extremely ham heavy)'; }
        elsif ( $norm < 0.9 )   { $normdesc = '(ok - slighly ham heavy)'; }
        elsif ( $norm < 1.1 )   { $normdesc = '(very good - balanced)'; }
        elsif ( $norm < 1.4 )   { $normdesc = '(ok - slighly spam heavy)'; }
        else                    { $normdesc = '(warning: extremely spam heavy)'; }
        &rb_printlog( "Corpus norm:\t%.4f - $normdesc\n", $norm );
        &rb_printlog( "Corpus confidence:\t%.8f\n", &main::BayesConfNorm() );
    }
    if ( $spamlogcount >= $main::MaxFiles || $notspamlogcount >= $main::MaxFiles ) {
        &rb_printlog(
            "Recommendation: RebuildSpamDB will limit the number of used messages in your corpus. Excess files will be ingored.\n"
          );
    }
    my ($lownorm,$highnorm,$numfiles,$mindays) = split(/-/o, $main::autoCorrectCorpus);
    if ( $norm < 0.6 ) {
        &rb_printlog("Corpus norm should be between 0.6 and 1.4\n");
        &rb_printlog("\nRecommendation: You need more spam messages in the corpus.\n");
    }
    if (! $main::RebuildTestMode && ! $neededspam && $main::autoCorrectCorpus && $norm < $lownorm && $main::notspamlog && ! $main::RunTaskNow{cleanUpMaxFiles}) {
        $main::RunTaskNow{cleanUpMaxFiles} = 10001;
        &rb_printlog("\nstarting auto correction for corpus - delete old ham files from $main::notspamlog\n");
        my $info = &main::cleanUpMaxFiles($main::notspamlog, 1 - $lownorm, $numfiles,$mindays);
        &rb_printlog($info) if $info;
        $main::RunTaskNow{cleanUpMaxFiles} = '';
    }
    if ( $norm > 1.4 ) {
        &rb_printlog("Corpus norm should be between 0.6 and 1.4\n");
        &rb_printlog("\nRecommendation: You need more not-spam messages in the corpus.\n");
    }
    if (! $main::RebuildTestMode && ! $neededspam && $main::autoCorrectCorpus && $norm > $highnorm && $main::spamlog && ! $main::RunTaskNow{cleanUpMaxFiles}) {
        $main::RunTaskNow{cleanUpMaxFiles} = 10001;
        &rb_printlog("\nstarting auto correction for corpus - delete old spam files from $main::spamlog\n");
        my $info = &main::cleanUpMaxFiles($main::spamlog, $highnorm - 1, $numfiles,$mindays);
        &rb_printlog($info) if $info;
        $main::RunTaskNow{cleanUpMaxFiles} = '';
    }
    if ( $main::MaxBytes >= 4000 && $norm < 0.6 ) {
        &rb_printlog( "\nRecommendation: You should reduce now MaxBytes to " . int( ( $main::MaxBytes + 1000 ) / 2 ) . "!  \n" );
    }
    if ( $main::MaxBytes <= 4000 && $norm > 1.3 ) {
        my $newMaxBytes = int( $main::MaxBytes - 1000 ) * 2 ;
        $newMaxBytes = $main::MaxBytes + 1000 if $newMaxBytes <= $main::MaxBytes;
        &rb_printlog( "\nRecommendation: You should increase now MaxBytes to " . $newMaxBytes . "!  \n" );
    }

    if ($DoHMM) {
        if ($main::spamdb eq 'DB:' or $main::runHMMusesBDB or $main::HMM4ISP) {
            $main::lockHMM = 1;
            &rb_mlog( "try to lock HMM databases in 5 second(s)" );
            sleep 5;
            $main::ThreadIdleTime{$main::WorkerNumber} += 5;
            &rb_printlog( "\nStart populating Hidden Markov Model. HMM-check is disabled for this time!\n" );
            &rb_mlog( "Start populating Hidden Markov Model. HMM-check is disabled for this time!" );
            rb_populate_HMM();
            &rb_printlog( "Finished populating Hidden Markov Model. HMM-check is now enabled again!\n" );
            &rb_mlog( "Finished populating Hidden Markov Model! HMM-check is now enabled again!" );
            $main::cleanHMM = '';
            $main::HMMdb{'***bayesnorm***'} = $norm;
        } else {
            &rb_printlog( "\nplease set the config parameter 'spamdb' to 'DB:' or 'HMMusesBDB' to 'On' - unable to populate HMM\n\n");
            &rb_mlog( "please set the config parameter 'spamdb' to 'DB:' or 'HMMusesBDB' to 'On' - unable to populate HMM");
        }

        $main::lockHMM = 0;
    }

    $processedBytes = &main::formatNumDataSize($processedBytes);
    if   ( time - $starttime != 0 ) { $processTime = &rb_commify(time - $starttime); }
    else                            { $processTime = 1; }
    &rb_printlog( "\nTotal processing time: %s second(s)\n", $processTime );
    &rb_printlog( "\nTotal processing data: $processedBytes\n\n");
    &rb_mlog( "Total processing time: %s second(s)", $processTime );
    &rb_mlog( "Total processed data: $processedBytes");

    if ($DoHMM && $scanFiles > 200) {
        use File::Find;
        my $size;
        my $used;
        find(sub{ -f and ( $size += -s ) }, "$main::base/tmpDB" );
        $used = $size;
        $size *= 2;
        $size = 250 * 1024 * 1024 if $size < 250 * 1024 * 1024;
        $size = &main::formatNumDataSize(int($size / 1024) * 1024);
        $used = &main::formatNumDataSize(int($used / 1024) * 1024);
        my $tooslow = 3; my $slow = $doattach ? 6 : 7; my $fast = $doattach ? 10 : 12;
        $scanTime = 1 unless $scanTime;
        my $fps = sprintf("%.2f",($scanFiles / $scanTime));
        if ($fps < $tooslow && $main::useDB4Rebuild) {
            &rb_printlog("\nRebuild processed $fps files per second. SPAMBOX expects a speed of at least $slow files per second - good values are $fast and higher. The disk IO components (disks and/or IO-controller) of your system are too slow for SPAMBOX. Use a cached (>=128MB) IO-controller or use a RAM-disk with at least $size for the folder '$main::base/tmpDB' to speed up the rebuild process or disable 'DoHMM'.\n");
            &rb_mlog("Rebuild processed $fps files per second. SPAMBOX expects a speed of at least $slow files per second - good values are $fast and higher. The disk IO components (disks and/or IO-controller) of your system are too slow for SPAMBOX. Use a cached (>=128MB) IO-controller or use a RAM-disk with at least $size for the folder '$main::base/tmpDB' to speed up the rebuild process or disable 'DoHMM'.");
        } elsif ($fps < $slow && $main::useDB4Rebuild) {
            &rb_printlog("\nRebuild processed $fps files per second. SPAMBOX expects a speed of at least $slow files per second - good values are $fast and higher. The disk IO components (disks and/or IO-controller) of your system are slow. Use a cached (>=128MB) IO-controller or use a RAM-disk with at least $size for the folder '$main::base/tmpDB' to speed up the rebuild process.\n");
            &rb_mlog("Rebuild processed $fps files per second. SPAMBOX expects a speed of at least $slow files per second - good values are $fast and higher. The disk IO components (disks and/or IO-controller) of your system are slow. Use a cached (>=128MB) IO-controller or use a RAM-disk with at least $size for the folder '$main::base/tmpDB' to speed up the rebuild process.");
        } elsif ($fps < $fast && $main::useDB4Rebuild) {
            &rb_printlog("\nRebuild processed $fps files per second. Good values are $fast files per second and higher. You can speed up the rebuild process, using a cached (>=128MB) IO-controller or a RAM-disk with at least $size for the folder '$main::base/tmpDB'.\n");
            &rb_mlog("Rebuild processed $fps files per second. Good values are $fast files per second and higher. You can speed up the rebuild process, using a cached (>=128MB) IO-controller or a RAM-disk with at least $size for the folder '$main::base/tmpDB'.");
        } else {
            &rb_printlog("\nRebuild processed $fps files per second.\n");
            &rb_mlog("Rebuild processed $fps files per second.");
        }
        if ($main::useDB4Rebuild) {
            &rb_printlog("\nAfter finishing the Rebuild process, the $main::base/tmpDB folder contains $used.\n");
            &rb_mlog("After finishing the Rebuild process, the $main::base/tmpDB folder contains $used.");
            if ($main::CanUseSPAMBOX_FC && eval('require SPAMBOX_FC;')) {
                $SPAMBOX_FC::freespace_kbl = 0;
                $SPAMBOX_FC::totalspace_kbl = 0;
                if ( &SPAMBOX_FC::getDriveInfo("$main::base/tmpDB",'l') && $SPAMBOX_FC::totalspace_kbl ) {
                    $SPAMBOX_FC::freespace_kbl =~ s/[.,]//go;
                    $SPAMBOX_FC::totalspace_kbl =~ s/[.,]//go;
                    $SPAMBOX_FC::freespace_kbl = &main::formatNumDataSize($SPAMBOX_FC::freespace_kbl * 1024);
                    $SPAMBOX_FC::totalspace_kbl = &main::formatNumDataSize($SPAMBOX_FC::totalspace_kbl * 1024);
                    &rb_printlog("\nAfter finishing the Rebuild process, the drive that contains the $main::base/tmpDB folder has $SPAMBOX_FC::freespace_kbl free space from total $SPAMBOX_FC::totalspace_kbl.\n");
                    &rb_mlog("After finishing the Rebuild process, the drive that contains the $main::base/tmpDB folder has $SPAMBOX_FC::freespace_kbl free space from total $SPAMBOX_FC::totalspace_kbl.");
                }
                eval('no SPAMBOX_FC;');
            }
        }
    }

    if ( $main::spamboxLog ) { &rb_uploadgriplist(); }

    if ($TrashlistObj !~ /orderedtie/o && (open my $HASH, '>', "$main::base/trashlist.db") ) {
        binmode $HASH;
        print $HASH "\n";
        foreach my $k (sort keys %Trashlist) {
            my $v = $Trashlist{$k};
            print $HASH "$k\002$v\n";
        }
        eval{close $HASH;};
        &rb_printlog( "\nTrashlist was saved to $main::base/trashlist.db\n" );
        &rb_mlog( "Trashlist was saved to $main::base/trashlist.db" );
    }
    eval{close $RebuildLog;};
    if ($main::RebuildNotify) {
        &main::sendNotification(
          $main::EmailFrom,
          $main::RebuildNotify,
          "RebuildSpamDB - report from $main::myName",
          "File rebuildrun.txt follows:\r\n\r\n",
          "$main::base/rebuildrun.txt");
    }

    }  # end if ($onlyNewCorrected)

    undef $spamObj;
    undef $newspamObj;
    undef $HeloObj;
    undef $HamHashObj;
    undef $SpamHashObj;
    undef $GpCntObj;
    undef $GpOKObj;
    undef $TrashlistObj;
    undef $HMMresObj;
    untie %spam;
    untie %newspam;
    untie %Helo;
    untie %HamHash;
    untie %SpamHash;
    untie %GpCnt;
    untie %GpOK;
    untie %Trashlist;
    untie %HMMres;

    undef $hamHMM;
    undef $spamHMM;

    undef $BDBEnv;

    unlink "$DBDir/rb_HMMres.bdb";
    unlink "$DBDir/rb_HamHash.bdb";
    unlink "$DBDir/rb_SpamHash.bdb";
    unlink "$DBDir/rb_GpCnt.bdb";
    unlink "$DBDir/rb_GpOK.bdb";
    unlink "$DBDir/rb_newspam.bdb";

eval (<<'EOT');
    no SPAMBOX_WordStem;
EOT
    return ! $have_error;
}
##########################################
#       run/main script ends here
##########################################

sub rb_populate_HMM {                 # rb_populate_HMM
    delete $HMMres{''};
    return rb_populate_HMM_DB() if $main::DBusedDriver ne 'BerkeleyDB' && ! $main::runHMMusesBDB && ! $main::HMM4ISP;
    %main::HMMdb = ();                # clear the main hash

    my $obj;
    if ($obj = tied %main::HMMdb) {
       &main::BDB_filter_off($obj) unless $main::HMM4ISP;
    }
    my $tot;
    eval (<<'EOT');
        $tot = defined $HMMresObj ? &rb_commify($HMMresObj->db_stat()->{hash_ndata}) : &rb_commify(scalar keys %HMMres);
EOT

    my $count = $main::haveHMM = 0;
    &rb_printlog( "start populating Hidden Markov Model with $tot records!\n" );
    &rb_mlog( "start populating Hidden Markov Model with $tot records!" );
    $main::cleanHMM = 1;
    while (my ($k,$v) = each %HMMres) {
        next unless defined $v;
        if ($count%1000==0) {
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
            $main::lastd{$Iam} = "populating HMM - ".&rb_commify($count)."/$tot";
        }
        $main::HMMdb{$k} = $v unless $main::RebuildTestMode;
        $count++;
    }
    $main::currentDBVersion{HMMdb} = $main::HMMdb{'***DB-VERSION***'} = $main::requiredDBVersion{HMMdb};
    &main::BDB_filter($obj) if $obj && ! $main::HMM4ISP;
    $main::haveHMM = $count;
    $main::cleanHMM = '' if $count;
    $count = &rb_commify($count);

    &rb_printlog( "Finished populating Hidden Markov Model with $count records!\n" );
    &rb_mlog( "Finished populating Hidden Markov Model with $count records!" );
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    return;
}

sub rb_populate_HMM_DB {                 # rb_populate_HMM_DB;
    my ($tot,$totn);
    eval (<<'EOT');
        $totn = defined $HMMresObj ? $HMMresObj->db_stat()->{hash_ndata} : scalar keys %HMMres;
        $tot = &rb_commify($totn);
EOT

    &rb_printlog( "start populating Hidden Markov Model with $tot records!\n" );
    &rb_mlog( "start populating Hidden Markov Model with $tot records!" );

    while ($main::ComWorker{$Iam}->{run} && $main::RunTaskNow{ImportMysqlDB}) {
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
        $main::lastd{$Iam} = "waiting additional 10 seconds for still running DB import to be finished";
        sleep 10;
        $main::ThreadIdleTime{$main::WorkerNumber} += 10;
    }
    die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};

    $main::haveHMM = 0;
    $main::cleanHMM = 1;
    $main::RunTaskNow{ImportMysqlDB} = $Iam;
    $main::lastd{$Iam} = "populating HMM - $tot records";
    &main::importDB('main::HMMdb','','hmmdb',\%HMMres,$totn, 1/2) unless $main::RebuildTestMode;
    $main::RunTaskNow{ImportMysqlDB} = '';
    $main::cleanHMM = 0 if ($main::haveHMM = &main::getDBCount('main::HMMdb','main::spamdb'));
    delete $main::HMMdb{''};
    $main::currentDBVersion{HMMdb} = $main::HMMdb{'***DB-VERSION***'} = $main::requiredDBVersion{HMMdb};
    &rb_printlog( "Finished populating Hidden Markov Model with $tot records!\n" );
    &rb_mlog( "Finished populating Hidden Markov Model with $tot records!" );
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    return;
}

sub rb_populate_Spamdb {
    my ($hashref, $totn) = @_;

    my $mainhashname = 'main::Spamdb';
    my $mysqlTable = lc $mainhashname;
    $mysqlTable =~ s/main:://o;
    my $tot = &rb_commify($totn);

    &rb_printlog( "start populating Spamdb with $tot records - Bayesian check is now disabled!\n" );
    &rb_mlog( "start populating Spamdb with $tot records - Bayesian check is now disabled!" );
    $main::lastd{$Iam} = "start populating Spamdb with $tot records!" ;

    while ($main::ComWorker{$Iam}->{run} && $main::RunTaskNow{ImportMysqlDB}) {
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
        $main::lastd{$Iam} = "waiting additional 10 seconds for still running DB import to be finished";
        sleep 10;
        $main::ThreadIdleTime{$main::WorkerNumber} += 10;
    }
    die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};

    $main::RunTaskNow{ImportMysqlDB} = $Iam;
    $main::lockBayes = 1;
    &rb_mlog( "try to lock Spamdb database in 5 second(s)" );
    sleep 5;
    $main::ThreadIdleTime{$main::WorkerNumber} += 5;
    $main::lastd{$Iam} = "populating Spamdb - $tot records";
    &main::importDB($mainhashname,'',$mysqlTable,$hashref,$totn, 1/2) unless $main::RebuildTestMode;
    $main::lockBayes = '';
    $main::RunTaskNow{ImportMysqlDB} = '';

    &rb_printlog( "Finished populating Spamdb with $tot records - Bayesian check is now enabled!\n" );
    &rb_mlog( "Finished populating Spamdb with $tot records - Bayesian check is now enabled!" );
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    return;
}

sub rb_Load_Trashlist {
       my $LH;
       unless (open($LH, '<',"$main::base/trashlist.db")) {
           return;
       }
       binmode($LH);
       while (<$LH>) {
         my ($k,$v) = split/\002/o;
         chomp $v;
         $v =~ s/\r|\n//go;
         if ($k && $v) {
           $Trashlist{$k}=$v;
         }
       }
       eval{close $LH;};
}

sub rb_BDB_getRecordCount {
    my $hash = shift;
    return 0 unless $hash;
    return 0 unless tied %{$hash};
    my $dbo = $hash . 'Obj';
    return 0 unless defined ${$dbo};
    return 0 if ("${$dbo}" !~ /BerkeleyDB/o);
    my $statref;
    eval (<<'EOT');
         $statref = ${$dbo}->db_stat();
EOT
    return 0 unless $statref;
    return 0 unless ref $statref;
    $main::lastd{$Iam} = "$hash BerkeleyDB record count: ".$statref->{hash_ndata};
    return $statref->{hash_ndata};
}


sub rb_generatescores {
    my ( $t, $s, $pair, $v );
    &rb_printlog("\nGenerating weighted Bayesian tuplets\n");
    my $spamdbFile;
    if (! $main::ReplaceOldSpamdb) {
        (open( $spamdbFile, '>', "$main::base/spamdb.rb.tmp" )) ||  &rb_printlog("unable to open $main::base/spamdb.rb.tmp: $!\n");
        binmode $spamdbFile;
        print { $spamdbFile } "\n";
    }
    my $totspam = &rb_BDB_getRecordCount('spam') || scalar keys %spam;
    my $count = 0;
    while ( ( $pair, $v ) = each(%spam) ) {
        next if (! $pair);
        $count++;
        if ($count%1000==0) {
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
            $main::lastd{$Iam} = "Generating weighted Bayesian tuplets $count/$totspam";
        }
        my ($s1, $t1) = ( $s, $t ) = split( q{ }, $v );
#        $t = ( $t - $s ) * $norm + $s;    # normalize t
        if ( $t1 > 3 ) {

            # if token represents all spam or all ham then square its value
            if ( $s1 == $t1 || $s1 == 0 ) {
                $s = $s * $s;
                $t = $t * $t;
            }
            $v = ( 1 + $s ) / ( $t + 2 );
            $v = sprintf( "%.7f", $v );
            $v = 0.9999999 if $v >= 1;
            $v = 0.0000001 if $v <= 0;
            if (abs( $v - .5 ) > .09) {
                $newspam{$pair} = $v;
                print { $spamdbFile } "$pair\002$v\n" if (! $main::ReplaceOldSpamdb);
            }
        }
    }
    my $nowspam = &rb_BDB_getRecordCount('newspam') || scalar keys %newspam;
    eval{close $spamdbFile;} if (! $main::ReplaceOldSpamdb);
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    my $oldspam = &main::getDBCount('main::Spamdb','main::spamdb');
    if ($main::ReplaceOldSpamdb) {
        if ($main::spamdb ne 'DB:' or
            ($main::spamdb eq 'DB:' and $main::DBusedDriver eq 'BerkeleyDB' and $main::CanUseBerkeleyDB))
        {
            $main::lastd{$Iam} = "populating $nowspam SpamDB records";
            &rb_printlog("populating Spamdb $nowspam records - Bayesian check is now disabled\n");
            &rb_mlog("populating $nowspam Spamdb records - Bayesian check is now disabled");
            $main::lockBayes = 1;
            &rb_mlog( "try to lock Spamdb database in 5 second(s)" );
            sleep 5;
            $main::ThreadIdleTime{$main::WorkerNumber} += 5;
            %main::Spamdb = %newspam;
            $main::lockBayes = '';
            $main::lastd{$Iam} = "finished populating SpamDB records: $nowspam";
            &rb_printlog("done - populating Spamdb records - $nowspam - Bayesian check is now enabled\n");
            &rb_mlog("done - populating Spamdb records - $nowspam - Bayesian check is now enabled");
        } else {
            rb_populate_Spamdb(\%newspam,$nowspam);
        }
    } else {
        $count = 0;
        $main::lastd{$Iam} = "add/modify $nowspam SpamDB records";
        &rb_printlog("add/modify Spamdb $nowspam records\n");
        &rb_mlog("add/modify Spamdb $nowspam records");
        while ( ( $pair, $v ) = each(%newspam) ) {
            $count++;
            if ($count%1000==0) {
                die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
                $main::lastd{$Iam} = "add/modify weighted Bayesian tuplets $count/$nowspam";
            }
            $main::Spamdb{$pair} = $v;
        }
        $main::lastd{$Iam} = "finished add/modify SpamDB records: $nowspam";
        &rb_printlog("done - add/modify Spamdb records - $nowspam\n");
        &rb_mlog("done - add/modify Spamdb records - $nowspam");
    }
    &rb_printlog("done - Generating weighted Bayesian tuplets\n");
    if (! $main::ReplaceOldSpamdb) {
        my $filesize = -s "$main::base/spamdb.rb.tmp";
        &rb_printlog( "\nResulting file '$main::base/spamdb.rb.tmp' is " . &rb_commify($filesize) . " bytes\n" );
    } else {
        &rb_printlog( "\n");
    }
    my $allpairs ;
    if ($main::ReplaceOldSpamdb) {
        $allpairs = $nowspam;
    } else {
        $allpairs = &main::getDBCount('main::Spamdb','main::spamdb');
    }
    &rb_printlog("Bayesian Pairs: " . &rb_commify($allpairs) . " now in list\n");
    &rb_mlog("Bayesian Pairs: " . &rb_commify($allpairs) . " now in list");
    $main::currentDBVersion{Spamdb} = $main::Spamdb{'***DB-VERSION***'} = $main::requiredDBVersion{Spamdb};
    %spam = ();
    return;
} ## end sub generatescores

sub rb_generateHMM {
    my $count = $spamHMM->{'chainsDB'} ? $spamHMM->{'chainsDB'}->db_stat()->{hash_ndata} : scalar keys %{$spamHMM->{chains}};
    $count +=   $spamHMM->{'totalsDB'} ? $spamHMM->{'totalsDB'}->db_stat()->{hash_ndata} : scalar keys %{$spamHMM->{totals}};
    $count +=   $hamHMM->{'chainsDB'}  ? $hamHMM->{'chainsDB' }->db_stat()->{hash_ndata} : scalar keys %{$hamHMM->{chains}};
    $count +=   $hamHMM->{'totalsDB'}  ? $hamHMM->{'totalsDB' }->db_stat()->{hash_ndata} : scalar keys %{$hamHMM->{totals}};
    $count = &rb_commify($count);
    &rb_printlog("\nGenerating consolidated Hidden-Markov-Model database from $count record model\n");
    &rb_mlog("Generating consolidated Hidden-Markov-Model database from $count record model");
    $count = 0;
    my $rec = 0;
    my $sep = $spamHMM->{seperator};
    while( my ($k,$sw) = each %{$spamHMM->{chains}} ) {
        $count++;
        if ($count%1000==0) {
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
            $main::lastd{$Iam} = "add HMM spam sequences $count";
        }
        my ($seq) = $k =~ /^(.+)$sep[^$sep]+$/;
        next unless ($seq);
        my $ht = $hamHMM->get_totals($seq);
        my $st = $spamHMM->get_totals($seq);
        if (my $tot = $ht + $st) {
            my $hw = $hamHMM->sequence_known($k);
            my $h = $hw / $tot;
            my $s = $sw / $tot;

            my $sp = (1 - $h + $s) / 2 ;
            $sp = 0.0000001 if $sp <= 0;
            $sp = 0.9999999 if $sp >= 1;
            if (abs( $sp - .5 ) > .09) {
                $HMMres{$k} = $sp;
                $rec++;
            }
        }
        delete ${$hamHMM->{chains}}{$k};
    }
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    while( my ($k,$hw) = each %{$hamHMM->{chains}} ) {
        $count++;
        if ($count%1000==0) {
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
            $main::lastd{$Iam} = "add HMM ham sequences $count";
        }
        my ($seq) = $k =~ /^(.+)$sep[^$sep]+$/;
        next unless ($seq);
        my $ht = $hamHMM->get_totals($seq);
        my $st = $spamHMM->get_totals($seq);
        if (my $tot = $ht + $st) {
            my $h = $hw / $tot;

            my $sp = (1 - $h) / 2 ;
            $sp = 0.0000001 if $sp <= 0;
            $sp = 0.9999999 if $sp >= 1;
            if (abs( $sp - .5 ) > .09) {
                $HMMres{$k} = $sp;
                $rec++;
            }
        }
    }
    &rb_printlog("HMM sequences: " . &rb_commify($rec) . " now in list\n\n");
    &rb_mlog("HMM sequences: " . &rb_commify($rec) . " now in list");
}

sub rb_createheloblacklist {
    (open( my $FheloBlack, '>', "$main::base/spamdb.helo.rb.tmp" )) || &rb_printlog("unable to open '$main::base/spamdb.helo.rb.tmp' $!\n");
    binmode $FheloBlack;
    print { $FheloBlack } "\n";
    my $count = &rb_commify(rb_BDB_getRecordCount('Helo') || scalar keys %Helo);
    &rb_mlog("generating Spamdb.helo records from $count collected HELO's");
    &rb_printlog("generating Spamdb.helo records from $count collected HELO's\n");
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    $count = 0;
    my $allcount = 0;
    my $notnew = 0;
    %main::HeloBlack = () if ($main::build lt 13080);
    while ( my ( $helostr, $weight ) = each(%Helo) ) {
        my $helostrlc = lc($helostr);
        my $spam = int($weight / 1000000);
        my $ham = $weight - $spam * 1000000;
# at least 5 spam weights without a ham weight [spam/(spam + 0 + .1) = 0.98 -> spam = 4.9] or
# at least 22 spam weights per ham weight      [spam/(spam + 1/3 + .1) = 0.98 -> spam = 21,7] to get HeloBlack
# at least 54 spam weights per ham weight      [spam/(spam + 1 + .1) = 0.98 -> spam = 53,9] to get HeloBlack
        my $w = $spam / ( $spam + $ham / 3 + .1 );
        if ( $w > .98 ) {
            $w = int($w + 0.5);
            print { $FheloBlack } "$helostrlc\002$w\n";
            $allcount++;
            if (exists $main::HeloBlack{$helostrlc}) {
                $notnew++;
            } elsif ($main::MaintenanceLog >= 2) {
                &rb_printlog("added new black helo '$helostrlc' to HeloBlackList\n");
                &rb_mlog("added new black helo '$helostrlc' to HeloBlackList");
            }
            $main::HeloBlack{$helostrlc} = $w;
        } elsif ($w < 0.12 && $ham > 3) {
            $w = sprintf("%.2f",(0.2 - $w));
            print { $FheloBlack } "$helostrlc\002$w\n";
            $allcount++;
            if (exists $main::HeloBlack{$helostrlc}) {
                $notnew++;
            } elsif ($main::MaintenanceLog >= 2) {
                &rb_printlog("added new good helo '$helostrlc' to HeloBlackList\n");
                &rb_mlog("added new good '$helostrlc' to HeloBlackList");
            }
            $main::HeloBlack{$helostrlc} = $w;
        } else {
            delete $Helo{$helostr};
        }
        $count++;
        if ($count%1000==0) {
            $main::lastd{$Iam} = "generating Spamdb.helo records $count";
            my $dbc = $main::HeloBlack{$helostr};
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
        }
    }
    eval{close $FheloBlack;};

    $count = 0;
    if ($main::ReplaceOldSpamdb && ! $onlyNewCorrected) {
        &rb_printlog("cleaning old Spamdb.helo records\n");
        &rb_mlog("cleaning old Spamdb.helo records");
        while ( my ( $helostr, $weights ) = each(%main::HeloBlack) ) {   #   clean old records from Spamdb.Helo
            $helostr = lc($helostr);
            delete $main::HeloBlack{$helostr} if (! exists $Helo{$helostr});
            $count++;
            if ($count%1000==0) {
                $main::lastd{$Iam} = "cleaning old Spamdb.helo records $count";
                die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
            }
        }
        &rb_printlog("done - cleaning old Spamdb.helo records\n");
        &rb_mlog("done - cleaning old Spamdb.helo records");
    }
    $count = &rb_commify(&main::getDBCount('main::HeloBlack','main::spamdb'));
    my $newhelos = &rb_commify($allcount - $notnew);
    my $text = ($main::ReplaceOldSpamdb) ? 'new' : 'in new mail';
    &rb_printlog( "\nHELO Blacklist: $newhelos $text, $count now in list\n" );
    &rb_mlog( "HELO Blacklist: $newhelos $text, $count now in list" );
    return;
}

sub rb_processNewCorrected {
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    $movetime = 0;
    my %addspam;
    my $newhamHMM  = SPAMBOX::MarkovChain->new(longest => $main::HMMSequenceLength,
                                          shortest => $main::HMMSequenceLength,
                                          top => 1,
                                          nostarts => 1,
                                          simple => 1
                                          );
    my $newspamHMM = SPAMBOX::MarkovChain->new(longest => $main::HMMSequenceLength,
                                          shortest => $main::HMMSequenceLength,
                                          top => 1,
                                          nostarts => 1,
                                          simple => 1
                                          );
# collect the SpamDB and HMM data from the files
    foreach my $file (sort { $main::newReported{$b} cmp $main::newReported{$a} } keys(%main::newReported) ) {
        my ($fldrType,$weight) = split(/\s+/o,$main::newReported{$file});
        if ($fldrType eq 'ham') {
            $weight += 4;
            $fldrType = 0;
        } else {
            $weight += 2;
            $fldrType = 1;
        }
        delete $main::newReported{$file};
        &rb_add( $fldrType, $file, $weight, \&rb_donohash, \%addspam ,$newspamHMM, $newhamHMM, 0 );
        rb_mlog("processed corrected file '$file' for SpamDB and HMMdb") if $main::MaintenanceLog > 1;
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
    }

    my $mod;
    my $del;
# calculate and update the SpamDB
    if ($main::haveSpamdb) {
        my $count = 0;
        my $deleted = 0;
        foreach (keys %addspam) {
            my ( $sfac, $tfac ) = split( q{ }, $addspam{ $_ } );
            my ( $sfao, $tfao ) = split( q{ }, $spam{ $_ } );
            $sfac += $sfao;
            $tfac += $tfao;
            $spam{ $_ } = $addspam{ $_ } = "$sfac $tfac";
        }
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};

        my ( $t, $s, $pair, $v );
        while ( ( $pair, $v ) = each(%addspam) ) {
            next if (! $pair);
            my ($s1, $t1) = ( $s, $t ) = split( q{ }, $v );
#            $t = ( $t - $s ) * $norm + $s;    # normalize t
            if ( $t1 > 3 ) {

                # if token represents all spam or all ham then square its value
                if ( $s1 == $t1 || $s1 == 0 ) {
                    $s = $s * $s;
                    $t = $t * $t;
                }
                $v = ( 1 + $s ) / ( $t + 2 );
                $v = sprintf( "%.7f", $v );
                $v = 0.9999999 if $v >= 1;
                $v = 0.0000001 if $v <= 0;
                if (abs( $v - .5 ) > .09) {
                    $main::Spamdb{$pair} = $v;
                    $count++;
                } else {
                    delete $main::Spamdb{$pair};
                    $deleted++;
                }
            }
        }
        $mod = "SpamDB($count)";
        $del = "SpamDB($deleted)";
    }
    die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
# calculate and update the HMMdb
    if ($DoHMM && $main::haveHMM) {
        my $count = 0;
        my $deleted = 0;
        my $sep = $newspamHMM->{seperator};
        foreach my $k (keys %{$newspamHMM->{chains}}) {
            my ($seq) = $k =~ /^(.+)$sep[^$sep]+$/;
            $newspamHMM->{totals}{$seq} += $spamHMM->{totals}{$seq};
            $spamHMM->{totals}{$seq} = $newspamHMM->{totals}{$seq};
            $newspamHMM->{chains}{$k} += $spamHMM->{chains}{$k};
            $spamHMM->{chains}{$k} = $newspamHMM->{chains}{$k};
        }
        foreach my $k (keys %{$newhamHMM->{chains}}) {
            my ($seq) = $k =~ /^(.+)$sep[^$sep]+$/;
            $newhamHMM->{totals}{$seq} += $hamHMM->{totals}{$seq};
            $hamHMM->{totals}{$seq} = $newhamHMM->{totals}{$seq};
            $newhamHMM->{chains}{$k} += $hamHMM->{chains}{$k};
            $hamHMM->{chains}{$k} = $newhamHMM->{chains}{$k};
        }
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};

        while( my ($k,$sw) = each %{$newspamHMM->{chains}} ) {
            my ($seq) = $k =~ /^(.+)$sep[^$sep]+$/;
            next unless ($seq);
            my $ht = $newhamHMM->get_totals($seq);
            my $st = $newspamHMM->get_totals($seq);
            if (my $tot = $ht + $st) {
                my $hw = $newhamHMM->sequence_known($k);
                my $h = $hw / $tot;
                my $s = $sw / $tot;

                my $sp = (1 - $h + $s) / 2 ;
                $sp = 0.0000001 if $sp <= 0;
                $sp = 0.9999999 if $sp >= 1;
                if (abs( $sp - .5 ) > .09) {
                    $main::HMMdb{$k} = $sp;
                    $count++;
                } else {
                    delete $main::HMMdb{$k};
                    $deleted++;
                }
            }
            delete ${$newhamHMM->{chains}}{$k};
        }
        &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
        while( my ($k,$hw) = each %{$newhamHMM->{chains}} ) {
            my ($seq) = $k =~ /^(.+)$sep[^$sep]+$/;
            next unless ($seq);
            my $ht = $newhamHMM->get_totals($seq);
            my $st = $newspamHMM->get_totals($seq);
            if (my $tot = $ht + $st) {
                my $h = $hw / $tot;

                my $sp = (1 - $h) / 2 ;
                $sp = 0.0000001 if $sp <= 0;
                $sp = 0.9999999 if $sp >= 1;
                if (abs( $sp - .5 ) > .09) {
                    $main::HMMdb{$k} = $sp;
                    $count++;
                } else {
                    delete $main::HMMdb{$k};
                    $deleted++;
                }
            }
        }
        $mod .= ' and ' if $mod;
        $mod .= "HMMdb($count)";
        $del .= ' and ' if $del;
        $del .= "HMMdb($deleted)";
    }
    if ($mod) {
        rb_mlog("updated $mod from new corrected files");
        rb_mlog("removed $del from new corrected files");
        rb_createheloblacklist();
    }
}

sub rb_processfolder {
    my ( $fldrType, $fldrpath, $filter, $weight, $sub, $MaxFiles, $neededHamWords, $neededSpamWords ) = @_;
    my ( $count, $pcount, $processFolderTime, $folderStartTime, $fileCount, @files, $deleteCount, $ignoreCount );
    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);
    $MaxFiles = $main::MaxFiles;
#    $MaxFiles ||= $main::MaxFiles;
#    $MaxFiles = &main::min($MaxFiles,$main::MaxFiles);
    $folderStartTime = time;
    $attachments = 0;
    my $flr = $fldrpath;
    $fldrpath = $main::base.'/'.$fldrpath;
    $fldrpath = &rb_fixPath($fldrpath);
    &rb_printlog( "\n" . $fldrpath . "\n" );
    &rb_mlog($fldrpath);
#   $fldrpath .= $filter eq "*" ? "/*" : "/*$filter";
    $fldrpath .= '/';
    $fileCount = &rb_countfiles($fldrpath);
    &rb_printlog( "File Count:\t" . &rb_commify($fileCount) );
    &rb_mlog( "File Count:\t" . &rb_commify($fileCount) );
    &rb_printlog("\nProcessing... $flr with ".&rb_commify(&main::min($fileCount,$MaxFiles))." files");
    &rb_mlog("Processing... $flr with ".&rb_commify(&main::min($fileCount,$MaxFiles))." files");
    $count = $RedCount = $WhiteCount = $deleteCount = 0;

    @files =  map { $_->[0] }
              sort { $b->[1] <=> $a->[1] }
              map { [ $_, &main::ftime($fldrpath.$_) ] } $main::unicodeDH->($fldrpath);  # youngest files first

    my ($spt,$nspt) = split(/\s+/o,($weight == 1 ? $main::MaxBayesFileAge : $main::MaxCorrectedDays));
    $nspt = $spt unless defined $nspt;
    $spt = $nspt if ! $fldrType;
    $spt *= 3600 * 24;
    my $rem = ($spt && $main::MaintBayesCollection) ? ' and remove' : '';
    &rb_printlog("\nignore$rem files older than ".&main::timestring($folderStartTime - $spt,'','')." in folder $flr") if $spt;
    &rb_mlog("ignore$rem files older than ".&main::timestring($folderStartTime - $spt,'','')." in folder $flr") if $spt;
    my %toolong;

    while (@files) {
        my $file = shift @files;
        $file = $fldrpath.$file;
        delete $main::newReported{$file};
        &main::ThreadYield();
        if ($count%100==0) {
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
            $main::lastd{$Iam} = "Processed $count/$fileCount files in $flr";
        }
        next if $main::dF->( $file );
        my $ftime = &main::ftime($file);
        next unless $ftime;
        my $dtime = $folderStartTime - $ftime;
        if ( $spt && $dtime > $spt ) {
            $count++;
            if ($main::MaintBayesCollection) {
                $main::unlink->($file);
                $deleteCount++;
                next;
            }
            $ignoreCount++;
            next;
        }
        if (($pcount - ( $RedCount + $WhiteCount )) < $MaxFiles)
        {    #too many files or words;
            my $heloOnly = ((! defined $neededHamWords) && (! defined $neededSpamWords))
                        || ($neededHamWords > 0 && $neededHamWords > $HamWordCount)
                        || ($neededSpamWords > 0 && $neededSpamWords > $SpamWordCount) ? 0 : 1;
            rb_d( 'file ('.++$pcount.")[$heloOnly]: $file");
            my $t = Time::HiRes::time();
            my $nocheck = &rb_add( $fldrType, $file, $weight, $sub, \%spam ,$spamHMM, $hamHMM, $heloOnly);
            delete $main::newReported{ $file };
            if (! $nocheck) {
                $t = Time::HiRes::time() - $t;
                if (($mintime && $t > $mintime) or ($movetime && $t > $movetime)) {
                    $t = sprintf("%.2f",$t);
                    &rb_d( "too long file processing time: $file - $t seconds" );
                    $toolong{$file} = $t;
                }
            }
            $count += $heloOnly ? 0 : 1;
        } elsif (! $spt) {     # stop if we don't have to remove old files
            $count++;
            last;
        }
    }
    if   ( time - $folderStartTime != 0 ) { $processFolderTime = time - $folderStartTime; }
    else                                  { $processFolderTime = 1; }
    $pcount = $pcount - ( $RedCount + $WhiteCount );
    if ($RedCount) {
        &rb_printlog( "\nRemoved Red:\t" . &rb_commify($RedCount) );
        &rb_mlog( "Removed Red:\t" . &rb_commify($RedCount) );
    }

    if ($WhiteCount) {
        &rb_printlog( "\nRemoved White:\t" . &rb_commify($WhiteCount) );
        &rb_mlog( "Removed White:\t" . &rb_commify($WhiteCount) );
    }

    if ($deleteCount) {
        &rb_printlog( "\nRemoved Old:\t" . &rb_commify($deleteCount) );
        &rb_mlog( "Removed Old:\t" . &rb_commify($deleteCount) );
    }

    if ($ignoreCount) {
        &rb_printlog( "\nIgnored:\t" . &rb_commify($ignoreCount) );
        &rb_mlog( "Ignored:\t" . &rb_commify($ignoreCount) );
    }

    if ($doattach) {
        rb_mlog(&rb_commify($attachments)." attachment/image entries processed");
        rb_printlog("\n".&rb_commify($attachments)." attachment/image entries processed");
    }

    &rb_printlog( "\nImported Files for HeloBlackList:\t" . &rb_commify($pcount) );
    &rb_mlog( "Imported Files for HeloBlackList:\t" . &rb_commify($pcount) );
    &rb_printlog( "\nImported Files for Bayes/HMM:\t" . &rb_commify($count) );
    &rb_mlog( "Imported Files for Bayes/HMM:\t" . &rb_commify($count) );

    if ( $count >= $main::MaxFiles ) {
        &rb_printlog("\nFolder contents exceeded 'MaxFiles'($main::MaxFiles). ");
        &rb_mlog("Folder contents exceeded 'MaxFiles'($main::MaxFiles). ");
    }

    if (($mintime or $movetime) && (my $tl = scalar keys %toolong)) {
        my $mtl = &main::min($tl,10);
        if ($mintime) {
            &rb_printlog("\nThe processing time of $tl file(s) in '$fldrpath' was longer than $mintime second(s) - now showing the $mtl longest");
            &rb_mlog("The processing time of $tl file(s) in '$fldrpath' was longer than $mintime second(s) - now showing the $mtl longest");
        }
        my $i = 0;
        my @toolong = sort { $toolong{$b} <=> $toolong{$a} } keys %toolong;
        while ( my $f = shift @toolong) {
            if ($mintime && (++$i <= $mtl)) {
                &rb_printlog("\n$f - $toolong{$f} s");
                rb_mlog("$f - $toolong{$f} s");
            }
            if ($movetime && $toolong{$f} > $movetime) {
                my $tofile = $f;
                my $base = $main::base;
                $tofile =~ s/^\Q$base\E\//$base\/rebuild_error\//;
                $main::unlink->($tofile);
                if ($main::move->($f,$tofile)) {
                    &rb_printlog("\nmoved file '$f' to '$tofile', because the processing time $toolong{$f} was longer than $movetime second(s)");
                    &rb_mlog("moved file '$f' to '$tofile', because the processing time $toolong{$f} was longer than $movetime second(s)");
                } else {
                    my $error = $!;
                    &rb_printlog("\ncan't moved file '$f' to '$tofile', the processing time $toolong{$f} was longer than $movetime second(s) - $error");
                    &rb_mlog("can't moved file '$f' to '$tofile', the processing time $toolong{$f} was longer than $movetime second(s) - $error");
                }
            }
        }
    }

# &rb_printlog( "\nfolder $flr: " . &rb_commify($SpamWordCount) . " spam weight \nfolder $flr: " . &rb_commify($HamWordCount) . " non-spam weight." );
    &rb_printlog("\nFinished in ".&rb_commify($processFolderTime)." second(s)\n");
    &rb_mlog("Finished in ".&rb_commify($processFolderTime)." second(s)");

    $scanTime += $processFolderTime;
    $scanFiles += $pcount;

    return $count;
} ## end sub processfolder

sub rb_countfiles {
    my ($fldrpath) = @_;
    my %fileCount;
    map {$fileCount{$_} = 1;} $main::unicodeDH->($fldrpath);
    delete $fileCount{'.'};
    delete $fileCount{'..'};
    return scalar(keys %fileCount);
}

sub rb_commify {
    my $r = shift;
    my $sep = $main::LogDateLang ? '.' : ',';
    1 while ($r =~ s/^([-+]?\d+)(\d{3})/$1$sep$2/o);
    return $r;
}

sub rb_hash {
    my $msgText = shift;

    # creates a md5 hash of $msg body
    if ( $$msgText =~ /^.*?\n\r?\n(.+)$/so ) {
        return eval{ Digest::MD5::md5_hex(substr($1,0,$main::MaxBytes)); };
    } else {
        return eval{ Digest::MD5::md5_hex(substr($$msgText,0,$main::MaxBytes)); };
    }
}

sub rb_dospamhash {
    my ( $FileName, $msgText ) = @_;
    $SpamHash{ &rb_hash($msgText) }++;
    return 0;
}

sub rb_dohamhash {
    my ( $FileName, $msgText ) = @_;
    $HamHash{ &rb_hash($msgText) }++;
    return 0;
}

sub rb_donohash {
    return 0;
}

sub rb_checkspam {
    my ( $FileName, $msgText ) = @_;
    my ( $return, $reason );
    if ( defined( $HamHash{ &rb_hash($msgText) } ) ) {

# we've found a message in the spam database that is the same as one in the corrected Ham group
        &rb_deletefile( $FileName, "corrected ham" );
        return 1;
    }
    elsif ( $reason = &rb_redlisted( $msgText ) ) {
        &rb_deletefile( $FileName, $reason );
        return 1;
    }
    elsif ( $reason = &rb_whitelisted( $msgText ) ) {
        &rb_deletefile( $FileName, $reason );
        return 1;
    }
    return 0;
}

sub rb_checkham {
    my ( $FileName, $msgText ) = @_;
    my ( $return, $reason );
    if ( defined( $SpamHash{ &rb_hash($msgText) } ) ) {

# we've found a message in the ham database that is the same as one in the corrected spam group
        &rb_deletefile( $FileName, "corrected spam" );
        return 1;
    }
    elsif ( $reason = &rb_redlisted( $msgText ) ) {
        &rb_deletefile( $FileName, "$reason" );
        return 1;
    }
    return 0;
}

sub rb_whitelisted {
    my $mm = shift;
    my $m = substr($$mm,0,$main::MaxBytes + 1000);
    my ( %seenf, %seent );

    # test against expression to recognize whitelisted mail
    my $mwr = $main::whiteReRE;
    if ( $main::whiteRe && $m =~ /($mwr)/ ) {
        my $reason = $1;
        $reason =~ s/\s+$/ /go;
        $reason =~ s/[\r\n\s]+/ /go;
        if ( length($reason) >= $main::RegExLength ) { $reason = substr( $reason, 0, ( $main::RegExLength - 4 ) ) . "..." }
        $WhiteCount++;
        return ( "Regex:White '" . $reason . q{'} );
    }
    $m =~ s/^($main::HeaderNameRe:$main::HeaderValueRe)+/$1/so;    # remove body

    my (@to,@from);
    while ( $m =~ /($main::HeaderNameRe):($main::HeaderValueRe)/igos ) {
        my ($h,$s) = ($1,$2);
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
        if ($h =~ /^(?:from|sender|X-Assp-Envelope-From|reply-to|errors-to|list-\w+)$/io) {
            &main::headerUnwrap($s);
            next unless ($s =~ /($main::EmailAdrRe\@$main::EmailDomainRe)/io);
            push @from , &main::batv_remove_tag(0,lc($1),'');
        }
        if ($h =~ /^(?:to|X-Assp-Intended-For)$/io) {
            &main::headerUnwrap($s);
            next unless ($s =~ /($main::EmailAdrRe\@$main::EmailDomainRe)/io);
            push @to , &main::batv_remove_tag(0,lc($1),'');
        }
    }
    while (my $curaddr = shift @from) {
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};

        if ( exists $seenf{ $curaddr } ) {
            next;                #we already checked this address
        } else {
            $seenf{ $curaddr } = 1;
        }
        foreach (@to) {
            if ( exists $seent{ $_ } ) {
                next;                #we already checked this address
            } else {
                $seent{ $_ } = 1;
            }
            if ( &main::Whitelist($curaddr,$_)) {
                $WhiteCount++;
                return ( "WhiteList: '$curaddr,$_'" );
            }
            if ($main::wildcardUser) {
                my ( $mfdd, $alldd, $reason );
                $mfdd = $1 if $curaddr =~ /(\@[^@]*)/o;
                $alldd = "$main::wildcardUser$mfdd";
                if ( &main::Whitelist( lc $alldd , $_) ) {
                    $WhiteCount++;
                    return ( "WhiteList-Wild: '$curaddr,$_'" );
                }
            }
        }
        %seent = ();
        if ($main::whiteListedDomains && &main::matchRE([$curaddr],'whiteListedDomains',1)) {
            $WhiteCount++;
            return ( "WhiteListed Domain: '" . $curaddr . q{'} );
        }
    } ## end while
    return 0;
} ## end sub whitelisted

sub rb_redlisted {
    my $mm = shift;
    my $m = substr($$mm,0,$main::MaxBytes + 1000);

    # test against expression to recognize redlisted mail
    if ( $main::DoNotCollectRedRe ) {    #skip Redre check, 1.3.5 and higher
        my $mrR = $main::redReRE;
        if ( $main::redRe && $m =~ /($mrR)/ ) {
            my $reason = $1;
            $reason =~ s/\s+$/ /go;
            $reason =~ s/[\r\n\s]+/ /go;
            if ( length($reason) >= $main::RegExLength ) { $reason = substr( $reason, 0, ( $main::RegExLength - 4 ) ) . "..." }
            $RedCount++;
            return ( "Regex:Red '" . $reason . q{'} );
        }
    }
    if ( $main::DoNotCollectRedList ) {    #skip Redlist check, 1.3.5 and higher
        $m =~ s/\n\r?\n.*$//so;                            # remove body
        while ( $m =~ /($main::EmailAdrRe\@$main::EmailDomainRe)/igo ) {
            my $curaddr = lc($1);
            die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};

            if ( $main::Redlist{ $curaddr } ) {
                $RedCount++;
                return ( "redlist: '" . $curaddr . q{'} );
            }
        }
    }
    return 0;
} ## end sub redlisted

sub rb_deletefile {
    my ( $fn, $reason, $ignorekeepdeleted ) = @_;

    if ( $main::eF->( $fn )) {
        &rb_printlog( "\nremove " . $fn . q{ } . $reason );
        if (! $main::RebuildTestMode) {
            if ( $main::MaxKeepDeleted && !$ignorekeepdeleted ) {
                $Trashlist{$fn} = time;
            } else {
                $main::unlink->($fn);
            }
        }
    } else {
        rb_printlog("\ncannot delete " . $reason . " message " . $fn . ": $!" );
    }
}

sub rb_get {
    my ( $fn, $sub , $factor) = @_;
    my $message;
    my $count;
    my $numreadchars;
    my $headlen;
    my $mBytes = $main::MaxBytes || 4000;
    my $ftime = &main::ftime($fn);
    return unless $ftime;
    my $dtime = $ftime - time;
    my $bodybytes = $mBytes * (($factor > 1) ? 4 : 2);

    return if $dtime > 0 or exists $Trashlist{$fn};
    my $file;
    $main::open->($file, '<', "$fn" ) or return;

    $file->binmode;
    $numreadchars = ($main::HeaderMaxLength ? $main::HeaderMaxLength : 10000) + $bodybytes;
#rb_d("rb_get - $fn - to read - $numreadchars - $file");
    $count = $file->read( $message, $numreadchars );    # read characters into memory
#rb_d("rb_get - $fn - read");
    eval{$file->close;};
    if ($count) {
        my @keep = $message =~ /((?:X-Assp-Reported-By|X-Assp-Intended-For|X-Forwarded-For):$main::HeaderValueRe)/gois;
        $message =~ s/X-SPAMBOX[^:]+:$main::HeaderValueRe//gois;                   # remove all X-SPAMBOX headers
        $message =~ s/(?:DKIM|DomainKey)-Signature:$main::HeaderValueRe//gios;  # remove DKIM/DomainKey signatures
        $message = join('',@keep).$message;
        $headlen = index($message, "\x0D\x0A\x0D\x0A");
        if ($headlen >= 0) {$headlen += 4;} else {$headlen = 0;}
        $message = substr($message, 0, $headlen + $bodybytes);
    } else {
        return;
    }
    return if $sub->( $fn, \substr($message, 0, $headlen + $mBytes ) );   # have i read this before?

    $processedBytes += length $message;
    return \$message, $headlen;
}

sub rb_checkRunTime {
    my ($StartTime, $text) = @_;
    return 0 unless $movetime;
    $rtText = $text if $text;
    return 0 if Time::HiRes::time() <= ($StartTime + $movetime);
    rb_d($rtText);
    return 1;
}

sub rb_add {
    my ( $isspam, $fn, $factor, $sub, $spam ,$spamHMM, $hamHMM, $heloOnly) = @_;
    return if $main::dF->( $fn );
    my $startTime = Time::HiRes::time();
    my ($content,$headerlen) = &rb_get( $fn, $sub , $factor);
    return unless $content;
    return if (rb_checkRunTime($startTime,"reached $movetime s after getting $fn"));
    my $imgHash;
    my $fsize = [$main::stat->( $fn )]->[7];
    if ($doattach && ! $heloOnly && ($fsize < $main::npSize) && ! exists $Trashlist{$fn.'.att'}) {
        $imgHash = &main::AttachMD5File($fn);
        $processedBytes += $fsize;
        if (rb_checkRunTime($startTime,"reached $movetime s after AttachMD5File on $fn")) {
            $Trashlist{$fn.'.att'} = time + (3600 * 24 * 5);
            $startTime = Time::HiRes::time();
            rb_printlog("\nfile '$fn' will be skipped from attachment processing in future rebuild tasks" );
            rb_mlog("file '$fn' will be skipped from attachment processing in future rebuild tasks" );
        }
    } elsif ($doattach && ! $heloOnly && ($fsize < $main::npSize)) {
        rb_d("file '$fn' will was skipped from attachment processing" );
    }
    my ( $curHelo, $CurWord, $PrevWord, $sfac, $tfac, $cip, $cipHelo );

    my $IPprivate = $main::IPprivate;
    my ($reportedBy,$domain);
    my $header;
    $header = substr($$content,0,$headerlen);
    if ($header) {
        $reportedBy = lc $1 if ($header =~ /X-Assp-Reported-By:\s*($main::EmailAdrRe\@$main::EmailDomainRe)/io);
        $reportedBy ||= lc $1 if ($header =~ /X-Assp-Intended-For:\s*($main::EmailAdrRe\@$main::EmailDomainRe)/io);
        $reportedBy ||= lc $1 if ($header =~ /^to:.*?($main::EmailAdrRe\@$main::EmailDomainRe)/io);
        ($domain) = $reportedBy =~ /(\@$main::EmailDomainRe)$/o;
        $reportedBy = '' unless (($main::DoPrivatSpamdb & 1) && &main::localmailaddress(0,$reportedBy));
        $domain = '' unless ($main::DoPrivatSpamdb > 1 && &main::localdomainsreal($domain));
        if ( $header =~ /X-Forwarded-For: ($IPRe)/io) {
            $cip = $1;
    		while ( $header =~ /Received:($main::HeaderValueRe)/gis ) {
                my $h = $1;
                if ( $h =~ /\s+from\s+(?:(\S+)\s)?(?:.+?)\Q$cip\E\]?\)(.{1,80})by.{1,20}/gis ) {
                    $cipHelo = $1;
                    $curHelo = $1 if $1;
                    my $rhelo = $2;
                    $cip = &main::ipv6expand(&main::ipv6TOipv4($cip));
                    $rhelo =~ s/\r?\n/ /go;
                    $curHelo = $cipHelo = $1 if $rhelo =~ /.+?helo\s*=?\s*([^\s\)]+)/io;
                }
            }
            if ($cip && &main::matchIP($cip,'ispip','',1)) {
                $cipHelo = '';
                $curHelo = '';
                $cip = '';
            }
        } elsif ( $main::ispHostnames ) {
            while ( $header =~ /Received:($main::HeaderValueRe)/gios ) {
                my $h = $1;
                if ( $h =~ /\s+from\s+(?:(\S+)\s)?(?:.+?)($IPRe)(.{1,80})by.{1,20}(?:$main::ispHostnamesRE)/gios ) {
                    $cip = $2;
                    $cipHelo = $1 || $cip;
                    my $rhelo = $3;
                    if ($cip =~ /$IPprivate/o) {
                        $cipHelo = '';
                        $rhelo = '';
                        next;
                    }

                    $cip = &main::ipv6expand(&main::ipv6TOipv4($cip));
                    $rhelo =~ s/\r?\n/ /gos;
                    $cipHelo = $1 if $rhelo =~ /helo\s*=?\s*([^\s\)]+)/io;
                }
            }
            if ($cip && &main::matchIP($cip,'ispip','',1)) {
                $cipHelo = '';
                $curHelo = '';
                $cip = '';
            }
        }

        my @myNames = ($main::myName);
        push @myNames , split(/[\|, ]+/o,$main::myNameAlso);
        my $myName = join('|', map {my $t = quotemeta($_);$t;} @myNames);

        if (   $myName
            && ! ($cipHelo or $curHelo)
            && $header =~ /Received: from (\S+).{1,20}\(\[($IPRe)(.{1,80})by.{1,20}(?:$myName)/is)
        {
            $curHelo = $1 || $2;
            my $ip = $2;
            my $rhelo = $3;
            if ($ip !~ /$IPprivate/o) {
                $cip = &main::ipv6expand(&main::ipv6TOipv4($ip));
                $rhelo =~ s/\r?\n/ /gos;
                $curHelo = $1 if $rhelo =~ / helo=([^\s\)]+)/io;
                if ($cip && &main::matchIP($cip,'ispip','',1)) {
                    $curHelo = '';
                    $cip = '';
                }
                if ($curHelo && $curHelo =~ /$main::ispHostnamesRE/) {
                    $curHelo = '';
                    $cip = '';
                }
            } else {
                $curHelo = '';
            }
        }
    }
    return if (rb_checkRunTime($startTime,"reached $movetime s after HELO parsing on $fn"));

    $cipHelo = lc($cipHelo);
    $curHelo = lc($curHelo);
    $cipHelo = '' if $cipHelo eq $curHelo;
    $Helo{ $cipHelo } += ( $isspam * 999999 + 1 ) * $factor if ( $cipHelo );
    $Helo{ $curHelo } += ( $isspam * 999999 + 1 ) * $factor if ( $curHelo );
    return 1 if $heloOnly;

    $$content =~  s/(?:X-Assp-Reported-By|X-Assp-Intended-For|X-Forwarded-For):$main::HeaderValueRe//gois;
    my $OK;
    ($content,$OK) = &main::clean($content);
    return if (rb_checkRunTime($startTime,"reached $movetime s after content cleanup on $fn"));
    my $BayesCont = $main::BayesCont;
    my @HMMhamWords;
    my @HMMspamWords;
    my $i = 0;
    foreach (keys %$imgHash) {
        if   ($isspam) { $SpamWordCount += $factor;}
        else           { $HamWordCount  += $factor;}
        ( $sfac, $tfac ) = split( q{ }, $spam->{ $_ } );
        $sfac += $isspam ? ($factor * 2) : 0;
        $tfac += ($factor * 2);
        $spam->{ $_ } = "$sfac $tfac";
        $i++;
        if ($reportedBy) {
            ( $sfac, $tfac ) = split( q{ }, $spam->{ "$reportedBy $_" } );
            $sfac += $isspam ? $factor : 0;
            $tfac += $factor;
            $spam->{ "$reportedBy $_" } = "$sfac $tfac";
        }
        if ($domain) {
            ( $sfac, $tfac ) = split( q{ }, $spam->{ "$domain $_" } );
            $sfac += $isspam ? $factor : 0;
            $tfac += $factor;
            $spam->{ "$domain $_" } = "$sfac $tfac";
        }
    }
    $attachments += $i;
    if ($doattach && $i) {
        rb_d("$i ".($isspam ? 'spam-' : 'ham-')."attachment/image entries processed in file $fn");
    }
    my $j = 0;
    rb_checkRunTime($startTime,"reached $movetime s in Bayes word pairs on $fn");
    my $ret = 1;
    use re 'eval';
    local $^R;
    while ( eval { $content =~ /([$BayesCont]{2,})(?{$1})/go } ) {
        my @Words;
        (@Words = &main::BayesWordClean($^R)) or next;
        while (@Words) {
            $CurWord = substr(shift(@Words),0,37);
            if ( ! $PrevWord ) {            # We only want word pairs
                $PrevWord = $CurWord;
                push(@HMMspamWords,$CurWord) if $DoHMM && $isspam;
                push(@HMMhamWords,$CurWord) if $DoHMM && ! $isspam;
                $i++;
                next;
            }

            # increment global weights, they are not really word counts
            if   ($isspam) { $SpamWordCount += $factor; push(@HMMspamWords,$CurWord) if $DoHMM && $i < $main::HMMDBWords;}
            else           { $HamWordCount  += $factor; push(@HMMhamWords,$CurWord) if $DoHMM && $i < $main::HMMDBWords;}
            ( $sfac, $tfac ) = split( q{ }, $spam->{ "$PrevWord $CurWord" } );
            $sfac += $isspam ? $factor : 0;
            $tfac += $factor;
            $spam->{ "$PrevWord $CurWord" } = "$sfac $tfac";
            if ($reportedBy) {
                ( $sfac, $tfac ) = split( q{ }, $spam->{ "$reportedBy $PrevWord $CurWord" } );
                $sfac += $isspam ? $factor : 0;
                $tfac += $factor;
                $spam->{ "$reportedBy $PrevWord $CurWord" } = "$sfac $tfac";
            }
            if ($domain) {
                ( $sfac, $tfac ) = split( q{ }, $spam->{ "$domain $PrevWord $CurWord" } );
                $sfac += $isspam ? $factor : 0;
                $tfac += $factor;
                $spam->{ "$domain $PrevWord $CurWord" } = "$sfac $tfac";
            }
            $PrevWord = $CurWord;
            $i++;
        }
        if ((++$j % 10 == 0) && rb_checkRunTime($startTime,'')) {$ret = undef; last;}
    } ## end while ( $content =~ /([$BayesCont]{2,})(?{$1})/go)
    if ($DoHMM) {
#        &rb_mlog( 'Rebuild: adding HMM: H = ' .scalar(@HMMhamWords).', S = '.scalar(@HMMspamWords).' words'.' P = '.$reportedBy);
        eval {
            if ($reportedBy && $isspam && @HMMspamWords > $main::HMMSequenceLength) {$spamHMM->seed(symbols => \@HMMspamWords, count => $factor, privacy => $reportedBy);}
            if ($reportedBy && !$isspam && @HMMhamWords > $main::HMMSequenceLength) {$hamHMM->seed(symbols => \@HMMhamWords, count => $factor, privacy => $reportedBy);}
            if ($domain && $isspam && @HMMspamWords > $main::HMMSequenceLength) {$spamHMM->seed(symbols => \@HMMspamWords, count => $factor, privacy => $domain);}
            if ($domain && !$isspam && @HMMhamWords > $main::HMMSequenceLength) {$hamHMM->seed(symbols => \@HMMhamWords, count => $factor, privacy => $domain);}
            if ($isspam && @HMMspamWords > $main::HMMSequenceLength) {$spamHMM->seed(symbols => \@HMMspamWords, count => $factor, privacy => '');}
            if (!$isspam && @HMMhamWords > $main::HMMSequenceLength) {$hamHMM->seed(symbols => \@HMMhamWords, count => $factor, privacy => '');}
            1;
        } or do{$DoHMM = 0;};    # stop HMM if we get an exception while processing (possibly file too large)
    }
    return $ret;
} ## end sub add

sub rb_printlog {
    my ( $text, $format, $notime ) = @_;
    my $lf = '';
    $lf = $1 if $text =~ s/^(\n+)//o;
    if ( ! $format ) {
        if ($text) {
            my $t = $notime ? '' : &main::timestring();
            print { $RebuildLog } $lf . $t . " $text" if ! $onlyNewCorrected;
            &main::d($text);
        } else {
            print { $RebuildLog } $lf if ! $onlyNewCorrected;
        }
    } else {
        if ($text) {
            my $t = $notime ? ' ' : &main::timestring().' ';
            print { $RebuildLog } $lf . $t if ! $onlyNewCorrected;
            printf $RebuildLog "$text", $format if ! $onlyNewCorrected;
            &main::d(sprintf("$text", $format));
        } else {
            print { $RebuildLog } $lf if ! $onlyNewCorrected;
        }
    }
    return;
}

sub rb_mlog {
    my ( $text, $format ) = @_;
    rb_d( $text, $format ) if $RebuildDebug;
    return unless $main::MaintenanceLog;
    if ( !$format ) {
        &main::mlog(0, "$text");
    }
    if ($format) {
        &main::mlog(0,(sprintf "$text", $format));
    }
    return;
}

sub rb_d {
    my ( $text, $format, $notime ) = @_;
    return if (! $RebuildDebug);
    my $t;
    $t = &main::timestring().' ' unless $notime;
    if ( !$format ) {
        print $RebuildDebug "$t$text\n";
    }
    if ($format) {
        print $RebuildDebug sprintf("$t$text\n", $format);
    }
    return;
}

sub rb_uploadgriplist {
    local $/ = "\n";

    &main::checkDBCon() if ($main::CanUseTieRDBM && $main::DBisUsed);

    &rb_printlog("\nbuilding new GripList records and bounce report\n") if !$main::noGripListUpload;
    &rb_mlog("building new GripList records and bounce report") if !$main::noGripListUpload;

    #&rb_printlog("Start building Griplist \n");
    my ( $date, $ip, $peeraddress, $hostaddress, $connect, $day, $gooddays, $last2days, $st );
    my ($logdir, $logdirfile) = $main::logfile=~/^(.*[\/\\])?(.*?)$/o;
    my @logfiles1=reverse sort( &main::Glob("$main::base/$logdir*$logdirfile") );
    my @logfiles;
    while (@logfiles1) {
        my $k = shift @logfiles1;
        push(@logfiles, $k) if $k !~ /b$logdirfile/;
    }

    #build list of the last 4 days
    my $time = time;
    $day = quotemeta(&main::timestring(undef,'d'));
    $gooddays  .= $day.'|';
    $last2days .= $day.'|';
    $day = quotemeta(&main::timestring( $time - 24 * 3600 , 'd'));
    $gooddays  .= $day.'|';
    $last2days .= $day;
    $day = quotemeta(&main::timestring( $time - 36 * 3600 , 'd'));
    $gooddays .= $day.'|';
    $day = quotemeta(&main::timestring( $time - 72 * 3600 , 'd'));
    $gooddays .= $day;
    undef $day;

    my $dayoffset = $time % ( 24 * 3600 );
    my %bounces = ();
    my $nbounces = 0;
    my $bbounces = 0;
    my $IPprivate = $main::IPprivate;
    while (@logfiles) {
        my $File = shift @logfiles;
        my $ftime = &main::ftime($File) || time;
        next if ( ( $ftime + 4 * 24 * 3600 ) < ( $time - $dayoffset ) );
        &rb_printlog("processing Logfile $File\n");
        &rb_mlog("processing Logfile $File");
        next unless (open( my $FLogFile, '<', "$File" ));
        while (<$FLogFile>) {
            if ( ( $ip ) = /(?:$gooddays) .*\s($IPRe)[ \]].* to: \S+/i) {
                next if $ip =~ /$IPprivate/o;                         # ignore private IP ranges
                next if &main::matchIP($ip,'acceptAllMail',0,1);
                $ip = &main::ipNetwork($ip, 1);
                if (! $main::noGripListUpload && /$main::HamTagRE/io) {

                    #Good IP
                    $GpCnt{ $ip } += 1;
                    $GpOK{ $ip }  += 1;
                } elsif (! $main::noGripListUpload && /$main::SpamTagRE|\[PenaltyDelay\]/o)
                {
                    next if /\[PersonalBlack\]/io;
                    #Bad IP
                    $GpCnt{ $ip } += 1;
                }
            }
            next if $main::DoNotCollectBounces;
            my $to;
            if (/^(?:$last2days) .+?\[isbounce\].+?bounce message detected/i) {
                $nbounces++;
                next;
            }
            ($to) = $1 if (/^(?:$last2days) .*?\[isbounce\].*?\sto:\s(\S+)\s/i);
            ($to) = $1 if (! $to && /^(?:$last2days) .*?\sto:\s(\S+)\s\[spam found\].*?failed for bounce sender/i );
            $to =~ s/\>+$//o;
            $to =~ s/^\<+//o;
            next unless $to;
            $bbounces++;
            $bounces{lc $to}++;
        }
        eval{close $FLogFile;};
    }
    $nbounces = &main::max($nbounces,$bbounces);
    if (! $main::DoNotCollectBounces && $nbounces) {
        my $pd = $main::EnableDelaying ? ' (possibly delayed)' : '';
        &rb_printlog("\nbounce report for the last two days: $nbounces bounces received$pd - $bbounces bounces blocked\n");
        &rb_printlog("\nlist of the top ten local addresses with blocked bounces in the last two days:\n\n") if $bbounces;
        my $i = 0;
        foreach my $adr ( sort { $bounces{$b} <=> $bounces{$a} } keys %bounces) {
            &rb_printlog("$adr : $bounces{$adr}\n",'',1);
            last if ++$i > 10;
        }
        &rb_printlog("\nend of bounce report\n\n");
    } elsif (! $main::DoNotCollectBounces) {
        &rb_printlog("\nbounce report for the last two days: no bounces received\n\n");
    } else {
        &rb_printlog("\nskipping bounce report because 'DoNotCollectBounces' is switched ON\n\n");
    }
    return if $main::noGripListUpload;

    if ( !%GpCnt ) {
        &rb_printlog("Skipping GrIPlist upload. Not enough messages processed.\n");
        &rb_mlog("Skipping GrIPlist upload. Not enough messages processed.");
        return;
    }
    my ($n6, $n4) = (0,0);
    while (my ($k,$v) = each %GpCnt) {
        next if (!$v);
        if (/:/o) {
            $n6++;
        }
        else {
            $n4++;
        }
    }
    $st = pack("N2", $n6 / 2**32, $n6);
    $st .= pack("N", $n4);
    my ($st6,$st4);
    while (my ($k,$v) = each %GpCnt) {
        next if (!$v);
        if ($k !~ /:/o) {
            my $ip = $k;
            $ip =~ s/([0-9a-f]*):/0000$1:/gio;
            $ip =~ s/0*([0-9a-f]{4}):/$1:/gio;
            $st6 .= pack("H4H4H4H4", split(/:/o, $ip));
            $st6 .= pack("C", (1 - $GpOK{$k} / $v) * 255);
        } else {
            $st4 .= pack("C3C", split(/\./o, $k), (1 - $GpOK{$k} / $v) * 255);
        }
    }
    $st .= $st6 . $st4;

    &main::downloadGripConf();  # reload the griplist.conf
    if ($main::proxyserver) {
        &rb_printlog("Uploading Griplist via Proxy: $main::proxyserver\n");
        &rb_mlog("Uploading Griplist via Proxy: $main::proxyserver");
        my $user = $main::proxyuser ? "$main::proxyuser:$main::proxypass\@": '';
        $peeraddress = $user . $main::proxyserver;
        $hostaddress = $main::proxyserver;
        $connect     = "POST $main::gripListUpUrl HTTP/1.0";
    } else {
        &rb_printlog("Uploading Griplist via Direct Connection\n");
        $peeraddress = $main::gripListUpHost . ':80';
        $hostaddress = $main::gripListUpHost;
        my ($url) = $main::gripListUpUrl =~ /http:\/\/[^\/](\/.+)/oi;
        $connect     = <<"EOF";
POST $url HTTP/1.1
User-Agent: SPAMBOX/$main::MAINVERSION ($^O; Perl/$];)
Host: $main::gripListUpHost
EOF
    }

    if ($main::RebuildTestMode) {
        &rb_printlog("unable to connect to $main::gripListUpHost to upload griplist\n");
        &rb_mlog("unable to connect to $main::gripListUpHost to upload griplist");
        return;
    }

    my $socket = $main::CanUseIOSocketINET6
                ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$peeraddress,Timeout=>2,&main::getDestSockDom($hostaddress),&main::getLocalAddress('HTTP',$peeraddress))
                : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$peeraddress,Timeout=>2,&main::getLocalAddress('HTTP',$peeraddress));

    if ( defined $socket ) {
        my $len = length($st);
        $connect .= <<"EOF";
Content-Type: application/x-www-form-urlencoded
Content-Length: $len

$st
EOF
        eval{$socket->blocking(0);};
        &main::NoLoopSyswrite( $socket , $connect, 0);
        sleep(1);
        eval{$socket->sysread($main::SMTPbuf, 4096);};
        $main::SMTPbuf = '';
        eval{$socket->close;};
        $len = &rb_commify($len);
        $n6 = &rb_commify($n6);
        $n4 = &rb_commify($n4);
        &rb_printlog("Submitted $len bytes: $n6 IPv6 addresses, $n4 IPv4 addresses\n");
        &rb_mlog("Submitted $len bytes: $n6 IPv6 addresses, $n4 IPv4 addresses");
    }
    else {
        &rb_printlog("unable to connect to $main::gripListUpHost to upload griplist\n");
        &rb_mlog("unable to connect to $main::gripListUpHost to upload griplist");
    }
    return;
} ## end sub uploadgriplist

sub rb_fixPath {
    my ($path) = @_;
    my $len = length($path);
    if   ( !substr( $path, ( $len - 1 ), 1 ) eq q{/} ) { return $path . q{/}; }
    else                                               { return $path; }
}

sub rb_move2num {
    &rb_movefiles('spamlog',$main::maillogExt);
    &rb_movefiles('notspamlog',$main::maillogExt);
    &rb_movefiles('correctednotspam',$main::maillogExt);
    &rb_movefiles('correctedspam',$main::maillogExt);
}

sub rb_movefiles {
    my ($foldername,$ext) = @_;
    my $folder = $main::base.'/'.${'main::'.$foldername};
    my $c=1;
    &rb_printlog("'move to num' started for $foldername\n");
    &rb_mlog("'move to num' started for $foldername");
    for my $fn ($main::unicodeDH->($folder)) {
        $fn = $folder.'/'.$fn;
        die "warning: got stop request from MainThread" unless $main::ComWorker{$Iam}->{run};
        next if $main::dF->( $fn );
        next if $fn=~/\/(\d+)$ext$/i && $1 < $main::MaxFiles;
        $c++;
        my $fn0=$fn;
        while ($c < $main::MaxFiles && [$main::stat->( "$folder/$c$main::maillogExt")]->[7]) {$c++}
        my $d=$c<$main::MaxFiles? $c: int(rand()*$main::MaxFiles);
        $fn=~s#/[^/]*$#/$d$ext#;
        $main::unlink->("$fn");
        $main::rename->("$fn0","$fn");
    }
    &rb_printlog("'move to num' processed $c files in $foldername\n");
    &rb_mlog("'move to num' processed $c files in $foldername");
}

sub rb_cleanTrashlist {
    my $files_before = my $files_deleted = 0;
    my $t = time;
    my $mcount;

    my @r;
    while ( my ( $k, $v ) = each(%Trashlist) ) {
        $files_before++;
        my $f = $k;
        $f =~ s/\.att$//o;
        if ($main::eF->( "$f" )) {
            if (  $t - $v >= $main::MaxKeepDeleted * 3600 * 24 )
            {
                &rb_deletefile ($f,"Trashlist",1);
                push @r,$k unless $main::RebuildTestMode;
                push @r,$f unless $main::RebuildTestMode;
                $files_deleted++;
            }
        } else {
            push @r,$k unless $main::RebuildTestMode;
            push @r,$f unless $main::RebuildTestMode;
            $files_deleted++;
        }
    }
    map {delete $Trashlist{$_};} @r;
    if ($files_before>0) {
        &rb_printlog("\nTrashlist cleaning finished, $files_deleted of $files_before files deleted\n");
        &rb_mlog("info: Trashlist cleaning finished, $files_deleted of $files_before files deleted");
    }
}

1;

