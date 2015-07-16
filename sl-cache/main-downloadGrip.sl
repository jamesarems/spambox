#line 1 "sub main::downloadGrip"
package main; sub downloadGrip {
    d('griplistdownload-start');
    my $ret;
    my $Iam = $WorkerNumber;
    my $old = 0;
    my $gripListDownUrlAdd;
    my $gripFile    = "$base/$griplist";
    my $dltime = time;
    my $n6;
    my $n4;
    my $dodelta;
    my %gripdelta;
    my $gripdeltaObj;
    my $bdbenv;

    mlog(0,"info: last full Griplist download was at: " .  timestring($Griplist{'255.255.255.255'}))  if $MaintenanceLog >= 2 && $Griplist{'255.255.255.255'};
    mlog(0,"info: last delta Griplist download was at: " . timestring($Griplist{'255.255.255.254'})) if $MaintenanceLog >= 2 && $Griplist{'255.255.255.254'};
    # check for previous bin download, so we can do delta now
    my $delta = '';
    if (-e "$gripFile.bin" && time - $Griplist{'255.255.255.255'} < 3600*24*7) {
        my $mtime = ftime("$gripFile.bin");  # full download once a week
        my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = gmtime($mtime);
	    $year += 1900;
	    $mon += 1;
	    $mtime = sprintf "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec;
        $gripListDownUrlAdd = "&delta=$mtime";
        $delta = " (delta)";
        $dodelta = 1;
    }
    return if(! $ComWorker{$Iam}->{run});
    return if(time - $Griplist{'255.255.255.254'} < 3550 && -e "$gripFile.bin");

    if (open(my $TEMPFILE, ">", "$gripFile.tmp")) {
        #we can create the file, this is good, now close the file and keep going.
        close $TEMPFILE;
        unlink("$gripFile.tmp");
    } else {
        &mlog(0,"Griplist download failed: Cannot create $gripFile.tmp") if $MaintenanceLog;
        return;
    }

    &downloadGripConf();  # reload the griplist.conf
    my $gripListDownUrlL = $gripListDownUrl . $gripListDownUrlAdd;
    $ret = downloadHTTP($gripListDownUrlL,
        "$gripFile.tmp",
        \$NextGriplistDownload,
        "Griplist$delta",5,9,2,1);

    return if(! $ComWorker{$Iam}->{run});

    if ($ret) {
        open my $tf, '<',"$gripFile.tmp";
        binmode $tf;
        while (<$tf>) {
            s/\r|\n//go;
            if (/error/oi) {
                &mlog(0,"Griplist download failed - see file $gripFile.tmp") if $MaintenanceLog;
                close $tf;
                return;
            }
        }
        close $tf;
        
        # download complete
        my $filesize = -s "$gripFile.tmp";
        &mlog(0,"Griplist download completed: binary download $filesize bytes") if $MaintenanceLog;

        # enough data?
        if ($filesize < 12) {
            &mlog(0,"Griplist download error: grip data too small") if $MaintenanceLog;
            unlink("$gripFile.tmp");
            return;
        }
        if (open(my $TEMPFILE, ">", "$gripFile.pl")) {
            #we can create the file, this is good
            binmode $TEMPFILE;
            print $TEMPFILE <<'EOT';
use strict;

my ($gripFile,$delta) = @ARGV;
my $dltime = time;
$gripFile =~ s/\\/\//go;
# if we did a delta download, read in previous data so we can merge
my @binFiles;
push(@binFiles, "$gripFile.bin") if ($delta);
push(@binFiles, "$gripFile.tmp");

# convert binary download form to text form used by ASSP
my $buf;
my %grip = ();
my %gripdelta = ();

my $action = "read";
foreach my $binF (@binFiles) {
    my $binSize = -s $binF;
    open(BIN, $binF);
    binmode(BIN);
    read(BIN, $buf, $binSize);
    close(BIN);
    my $deltayonly = ($binF eq "$gripFile.tmp");

    # IPv6 count
    my ($n6h, $n6l) = unpack("N2", $buf);
    my $n6 = $n6h * 2**32 + $n6l;

    # IPv4 count
    my $n4 = unpack("x[N2] N", $buf);

    # decode IPv6 data
    my $x6 = 0;
    for (my $i = 0; $i < $n6; $i++) {
        my ($bip, $grey) = unpack("x[N2] x[N] x$x6 a8 C", $buf);
        my $ip = join(":", unpack("H4H4H4H4", $bip)) . ":";
        $ip =~ s/:0+([0-9a-f])/:$1/gio;
        $ip =~ s/:0:$/::/o;

        #                $grip{$ip} = $grey / 255;
        #                $gripdelta{$ip} = $grey / 255 if $deltayonly;
        $x6 += 9;
    }

    # decode IPv4 data
    my $x4 = 0;
    for (my $i = 0; $i < $n4; $i++) {
        my ($bip, $grey) = unpack("x[N2] x[N] x$x6 x$x4 a3 C", $buf);
        my $ip = join(".", unpack("C3", $bip));
        $grip{$ip} = $grey / 255;
        $gripdelta{$ip} = $grey / 255 if $deltayonly;
        $x4 += 4;
    }

    &gmlog("Griplist binary $action OK: $binF, $n6 IPv6 addresses, $n4 IPv4 addresses");
#    &gmlog("Griplist binary $action OK: $binF, $n4 IPv4 addresses");
    $action = "merge";
}

# remove download file
unlink("$gripFile.tmp");

# output binary version, so we can do a delta next time
&gmlog("Writing merged Griplist binary");
my $n6 = 0;
my $n4 = 0;
my ($buf6, $buf4);
while ( my ($ip,$v) = each %grip) {
    if ($ip =~ /:/o) {
        my $ip2 = $ip;
        $ip2 =~ s/([0-9a-f]*):/0000$1:/gio;
        $ip2 =~ s/0*([0-9a-f]{4}):/$1:/gio;
        $buf6 .= pack("H4H4H4H4", split(/:/o, $ip2));
        $buf6 .= pack("C", int($v * 255));
        $n6++;
    } else {
        $buf4 .= pack("C3C", split(/\./o, $ip), int($v * 255));
        $n4++;
    }
}
$buf = pack("N2", $n6/2**32, $n6);
$buf .= pack("N", $n4);
unlink("$gripFile.bin");
open (BIN, ">$gripFile.bin");
binmode(BIN);
print BIN $buf . $buf6 . $buf4;
close(BIN);
chmod 0644, "$gripFile.bin";
utime($dltime, $dltime, "$gripFile.bin"); # important - sets file's time to UTC for next delta time
&gmlog("Writing merged Griplist binary finished");

# output text version
unlink("$gripFile.delta");
unlink("$gripFile");
open (TEXT, ">$gripFile");
binmode(TEXT);
print TEXT "\n";
foreach my $ip (sort keys %grip) {
    printf TEXT "$ip\002%.2f\n", $grip{$ip};
}
close(TEXT);
gmlog("OK-$gripFile");

# output text version delta
open (TEXT, ">$gripFile.delta");
binmode(TEXT);
print TEXT "\n";
foreach my $ip (sort keys %gripdelta) {
    printf TEXT "$ip\002%.2f\n", $grip{$ip};
}
close(TEXT);
gmlog("OK-$gripFile.delta");

sub gmlog {
    my $text = shift;
    $text =~ s/\r|\n//go;
    $text .= "\n";
    print $text;
}
EOT
            close $TEMPFILE;
        } else {
            &mlog(0,"Griplist download failed: Cannot create $gripFile.pl") if $MaintenanceLog;
            return;
        }

        if (! -e "$gripFile.pl") {
            &mlog(0,"Griplist - download failed: Cannot find $gripFile.pl") if $MaintenanceLog;
            return;
        }
        
        &mlog(0,'Griplist - starting binary to text conversion for Griplist') if $MaintenanceLog;
        d('Griplist - starting binary to text conversion for Griplist');
        my $perl = $perl;
        my $cmd = "\"$perl\" \"$gripFile.pl\" \"$gripFile\" \"$delta\"";
        $cmd =~ s/\//\\/go if $^O eq "MSWin32";
        my $out = qx($cmd);

        foreach (split(/\n/o,$out)) {
            s/\r|\n//go;
            if (/^OK-(.+)$/io) {
                mlog(0,"Griplist - converted file $1 found - OK") if $MaintenanceLog >= 2;
                next;
            }
            mlog(0,$_) if $MaintenanceLog;
        }
        unlink("$gripFile.pl");

        if ($CanUseBerkeleyDB && ($useDB4IntCache or $useDB4griplist)) {
            mlog(0,"Griplist update uses BerkeleyDB for temporary hashes") if $MaintenanceLog;
            -d "$base/tmpDB/gripdelta" or mkdir "$base/tmpDB/gripdelta",0775;

eval (<<'EOT');
          $bdbenv = BerkeleyDB::Env->new(-Flags => DB_CREATE | DB_INIT_MPOOL,
                                      -Cachesize => 5242880 ,
                                      -Home => "$base/tmpDB/gripdelta",
                                      -ErrFile => "$base/tmpDB/gripdelta/BDB-error.txt" ,
                                      -Config => {DB_DATA_DIR => "$base/tmpDB/gripdelta",
                                                  DB_LOG_DIR  => "$base/tmpDB/gripdelta",
                                                  DB_TMP_DIR  => "$base/tmpDB/gripdelta"}
                                              );

          $gripdeltaObj=tie %gripdelta,'BerkeleyDB::Hash',
                                     (-Filename => "$base/tmpDB/gripdelta/gripdelta.bdb" ,
                                      -Flags => DB_CREATE,
                                      -Env => $bdbenv);
EOT

            if ($@ or $BerkeleyDB::Error !~ /: 0\s*$/o) {
                mlog(0,"BerkeleyDB-ENV-ERROR gripdelta: $@ - BDB:$BerkeleyDB::Error");
            }
        } elsif ($CanUseDB_File && $useDB4IntCache) {
            mlog(0,"Griplist update uses DB_File for temporary hashes") if $MaintenanceLog;
eval (<<'EOT');
        $gripdeltaObj = tie %gripdelta, 'DB_File', "$base/tmpDB/gripdelta/gripdelta.bdb";
EOT
            mlog(0,"Griplist - DB_File-ERROR: $@") if $@;
        }

        my $nd = 0;my $TEMPFILE;
        if ($dodelta) {
            open $TEMPFILE,'<', "$gripFile.delta" ;
        } else {
            open $TEMPFILE,'<', "$gripFile" ;
        }
        $n4 = $n6 = 0;
        while (<$TEMPFILE>) {
            my ($k,$v) = split/\002/o;
            chomp $v;
            next unless ($k && $v);
            next if $k =~ /$IPprivate/o;
            if ($k =~ /:/o) {
                $n6++;
            } else {
                $n4++;
            }
            $Griplist{$k} = $v;
            $gripdelta{$k} = $v unless $dodelta;
            $nd++;
            if ($nd%1000 == 0) {
                threads->yield();
                $lastd{10000} = "Griplist - reading $nd records";
            }
            last if(! $ComWorker{$Iam}->{run});
        }
        close $TEMPFILE;
        &BDB_sync_hash('Griplist') if "$GriplistObj" =~ /BerkeleyDB/o;
        mlog(0,"Griplist - finished adding/updating ".nN($nd)." new records") if $MaintenanceLog;
        if (! $dodelta) {
            return if(! $ComWorker{$Iam}->{run});
            mlog(0,'Griplist - start remove old records after full download') if $MaintenanceLog;
            d('Griplist - start remove old records after full download');
            $nd = 0;
            while ( my ($ip,$v) = each %Griplist) {
                if (! exists $gripdelta{$ip}
                    && $ip ne 'x'
                    && $ip ne '255.255.255.255'
                    && $ip ne '255.255.255.254')
                {
                    delete $Griplist{$ip};
                    $nd++;
                }
                if ($nd%1000 == 0) {
                    threads->yield();
                    $lastd{10000} = "Griplist - deleting ".nN($nd)." old records";
                }
                last if(! $ComWorker{$Iam}->{run});
            }
            mlog(0,"Griplist - finished removing ".nN($nd)." old records") if $MaintenanceLog;
            &BDB_sync_hash('Griplist') if "$GriplistObj" =~ /BerkeleyDB/o;;
        }

        %gripdelta = ();
        undef $gripdeltaObj;
        eval{untie %gripdelta;};
        undef %gripdelta;
        undef $bdbenv;
        unlink "$base/tmpDB/gripdelta/gripdelta.bdb";
        unlink "$base/tmpDB/gripdelta/__db.001";
        unlink "$base/tmpDB/gripdelta/__db.002";
        unlink "$base/tmpDB/gripdelta/__db.003";
        unlink "$base/tmpDB/gripdelta/__db.004";

        $Griplist{'255.255.255.255'} = time if (! $dodelta || ! exists $Griplist{'255.255.255.255'});  # last full download
        $Griplist{'255.255.255.254'} = time;               # last download
        if ($ispgripvalue eq '') {
            mlog(0,"Griplist - calculating ISP grey value") if $MaintenanceLog;
            my $ns = 0;
            my $nh = 0;
            my $nd = 0;
            while ( my ($ip,$v) = each %Griplist) {
                next if $ip eq '255.255.255.255';
                next if $ip eq '255.255.255.254';
                next if $ip eq 'x';
                if ($v > $baysProbability) {$ns++;} else {$nh++;}
                $nd++;
                if ($nd%1000 == 0) {
                    threads->yield();
                    $lastd{10000} = "Griplist - ".nN($nd)." records - for ISP grey value";
                }
                last if(! $ComWorker{$Iam}->{run});
            }
            if($ComWorker{$Iam}->{run}) {
                my $x = sprintf("%.3f", $ns / ($ns + $nh + 1) );
                $x = 0.99 if $x >= 1;
                mlog(0,"Griplist - ISP grey value is set to $x (s:$ns , h:$nh)") if $MaintenanceLog;
                $Griplist{x} = $x;
            }
        }
        
        mlog(0,"Griplist update complete: ".nN($n6)." IPv6 addresses, ".nN($n4)." IPv4 addresses\n");

        if ($GriplistDriver eq 'orderedtie') {
            $GriplistObj->flush();
            $GriplistObj->{updated} = {};
        } elsif (open(my $F, '>', "$base/$griplist")) {
            binmode $F;
            print $F "\n";
            while ( my ($ip,$v) = each %Griplist) {
                print $F "$ip\002$v\n" if $ip && $v;
            }
            close $F;
        }
        
        $ConfigChanged = 1;         # tell all to reload Config
    }
    unlink("$gripFile.tmp");
    return $ret;
}
