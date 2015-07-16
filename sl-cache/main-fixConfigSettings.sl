#line 1 "sub main::fixConfigSettings"
package main; sub fixConfigSettings {
    $Config{base}=$base;

    $Config{baysNonSpamLog} = 0 if $Config{baysNonSpamLog} == 6;

    $Config{webAdminPassword}=crypt($Config{webAdminPassword},"45") if substr($Config{webAdminPassword}, 0, 2) ne "45";

    &fixV1ConfigSettings() if substr($Config{spamboxCfgVersion},0,1) < 2 ;

    $Config{redRe}="file:files/redre.txt" if $Config{redRe}=~/file:redre.txt/io;
    $Config{noDelay}="file:files/nodelay.txt" if $Config{noDelay}=~/file:nodelay.txt/io;

    $Config{ReStartSchedule} = 'noschedule' unless $Config{ReStartSchedule};

    if ($Config{SSLtimeout} == 180) {
        mlog(0,"warning: value '$Config{SSLtimeout}' in SSLtimeout was set to 5");
        $Config{SSLtimeout} = 5;
    }

    if ($Config{DoPrivatSpamdb} && $Config{spamdb} !~ /DB:/io) {
        mlog(0,"warning: DoPrivatSpamdb is set to '0' because spamdb is not configured to use any database 'DB:'");
        $Config{DoPrivatSpamdb} = 0;
    }

    if ($Config{allowAdminConnectionsFromName}) {
        my $host = $Config{allowAdminConnectionsFrom};
        $host .= '|' if $host;
        $host .= $Config{allowAdminConnectionsFromName};
        $Config{allowAdminConnectionsFrom} = $host;
        delete $Config{allowAdminConnectionsFromName};
    }

    if ($Config{EmailFrom} =~ /ASSP <>/io) {
        mlog(0,"warning: invalid value '$Config{EmailFrom}' in EmailFrom was set to ''");
        $EmailFrom = $Config{EmailFrom} = '';
    }

    if ($Config{EmailFrom} eq '' && ($defaultLocalHost || $EmailBlockReportDomain)) {
        my $host = $defaultLocalHost;
        $host ||= $EmailBlockReportDomain;
        $EmailFrom = $Config{EmailFrom} = "postmaster\@$host";
        mlog(0,"info: empty value '' in EmailFrom was set to '$EmailFrom'");
    }
    
    if (exists $Config{DNSTimeout}) {
        delete $Config{DNSTimeout};
    }
    if (exists $Config{CleanCacheInterval}) {
        delete $Config{CleanCacheInterval}; }
    if (exists $Config{DNSServer}) {
        delete $Config{DNSServer};
    }
    if (exists $Config{ExtensionsToBlock}) {
        $Config{BadAttachL1}=$Config{ExtensionsToBlock};

        # ExtensionsToBlock is not used in this version
        delete $Config{ExtensionsToBlock};
    }
    if (exists $Config{EmailWhitelist}) {
        $Config{EmailWhitelistAdd}=$Config{EmailWhitelist};

        # EmailWhitelist is not used in this version
        delete $Config{EmailWhitelist};
    }
    if (! exists $Config{AutoUpdateASSP}) {
        $Config{AutoRestartAfterCodeChange} = 'immed' if $Config{AutoRestartAfterCodeChange} == 1;
    }

    if (exists $Config{myHelo} && $Config{myHelo} =~ s/^\s*(\d)\s*$/$1/o) {
        my %hl = (0 => '' , 1 => 'MYNAME | MYNAME' , 2 => 'FQDN | FQDN' , 3 => 'IP | IP');
        $Config{myHelo} = $hl{$1};
        mlog(0,"info: value '$1' in myHelo was set to '$Config{myHelo}'");
    }
    
    if ($Config{BayesMaxProcessTime} > 15) {
        $BayesMaxProcessTime = $Config{BayesMaxProcessTime} = 15;
    }
    if ($maxBayesValues > 30 && ! -e "$base/lib/ASSP_WordStem.pm") {
       $maxBayesValues = 30;
    }
    $maxBayesValues = 30 if $maxBayesValues < 30;
    
    $Config{noMaxAUTHErrorIPs} = $Config{noBlockingIPs} if (exists $newConfig{noMaxAUTHErrorIPs});

    $Config{MaxEqualXHeader} = '*=>'.$Config{MaxEqualXHeader} if $Config{MaxEqualXHeader} =~ /^\d+$/;
    
    $Config{bayslocalValencePB} = $Config{baysValencePB_local} if exists $Config{baysValencePB_local};

    if (! exists $Config{yesBayesian_local}) {  # there was no V1 upgrade for yesBayesian_local
        if (! exists $Config{BayesLocal} && $Config{Bayesian_localOnly}) {      # local Bayes was set to on in previouse V2 version
            $newConfig{BayesLocal} = $Config{BayesLocal} = 1;
        }
    }

    delete $Config{UUID} if ($Config{UUID} !~ /^(?:[a-fA-F0-9]{2}){5,}$/o);
    
    $Config{autoCorrectCorpus} .= '-14' if $Config{autoCorrectCorpus} =~ /^\d\.\d\d?-\d\.\d\d?-(?:[4-9]\d{3}|\d{5,})$/o;

    $Config{useDB_File} = '' if (! $Config{PopB4SMTPFile});

    $Config{DoRFC822} = 0 if (! $Config{DoRFC822} && ! exists $newConfig{DoRFC822});

    $Config{DoHeaderAddrCheck} = '' if (length $Config{DoHeaderAddrCheck} > 1);

# -- cleanup old BerkeleyDB cache files
    if (-d "$base/tmpDB/dbmain" or -d "$base/tmpDB/dbtmp") {
        foreach ( Glob("$base/tmpDB/dbmain/*")) {
            unlink($_);
        }
        foreach ( Glob("$base/tmpDB/dbtmp/*")) {
            unlink($_);
        }
        foreach ( Glob("$base/tmpDB/*")) {
            if (-d $_) {
                rmdir($_);
            } else {
                unlink($_);
            }
        }

        my $bd2f;
        if ($Config{useDB4IntCache} &&
            $CanUseBerkeleyDB &&
            $Config{DoBackSctr} &&
            $Config{downloadBackDNSFile} &&
            ( ($bd2f) = $Config{localBackDNSFile} =~ /^ *file: *(.+)/io) &&
            -e "$base/$bd2f.BDB" )
        {
            -d "$base/tmpDB/BackDNS2" or mkdir "$base/tmpDB/BackDNS2" ,0775;
            move "$base/$bd2f.BDB","$base/tmpDB/BackDNS2/BackDNS2.bdb";
        }
    }

# -- check and set the used or available encryption engine
    $CanUseCryptGhost = $AvailCryptGhost = ASSP::CRYPT->new('a',0,0)->ENCRYPT('a') ne ASSP::CRYPT->new('a',0,1)->ENCRYPT('a');
    if ($Config{adminusersdbpass} && $Config{adminusersdbpass} =~ /^(?:[a-fA-F0-9]{2}){5,}$/o) {
        if ($AvailCryptGhost && defined ASSP::CRYPT->new($Config{webAdminPassword},0,1)->DECRYPT($Config{adminusersdbpass})) {
            $usedCrypt = 1; # can and use Crypt::GOST
        } elsif ($AvailCryptGhost && defined ASSP::CRYPT->new($Config{webAdminPassword},0,0)->DECRYPT($Config{adminusersdbpass})) {
            $CanUseCryptGhost = 0;
            $usedCrypt = -1; # can but don't use Crypt::GOST - try a later engine change
            mlog(0,"info: the old encryption engine is still used, but the new, faster one (Crypt::GOST) is available - the engine will be changed at a later time");
        } elsif (defined ASSP::CRYPT->new($Config{webAdminPassword},0,0)->DECRYPT($Config{adminusersdbpass})) {
            $usedCrypt = 0;  # can't and don't use Crypt::GOST
        } else {
            mlog(0,"error: encryption engine ERROR - unable to decrypt the value for 'adminusersdbpass'");
        }
    } else {
        $usedCrypt = 1;
    }

# -- decrypt/encrypt security vars
    my $dec = ASSP::CRYPT->new($Config{webAdminPassword},0);
    foreach (keys %cryptConfigVars) {
        $Config{$_} = $dec->DECRYPT($Config{$_}) if ($Config{$_} =~ /^(?:[a-fA-F0-9]{2}){5,}$/o && defined $dec->DECRYPT($Config{$_})) ;
    }
    $Config{adminusersdbpass} = $Config{webAdminPassword} unless $Config{adminusersdbpass};
    $Config{SNMPUser} = 'root' unless $Config{SNMPUser};

    ASSP::UUID::init();
    if (   ! exists $Config{UUID}
        || ! ASSP::UUID::is_uuid_string($Config{UUID})
        || ! ASSP::UUID::version_of_uuid($Config{UUID}) == 1)
    {
        mlog(0,"error: invalid ASSP - UUID and License Indentifier was found  : '$Config{UUID}'") if exists $Config{UUID};
        if ($Config{UUID} = ASSP::UUID::create_uuid_as_string()) {
            mlog(0,"AdminInfo: a new ASSP - UUID and License Indentifier was created for this installation : '$Config{UUID}'");
            mlog(0,"AdminUpdate: a new ASSP - UUID and License Indentifier was created for this installation : '$Config{UUID}'");
        } else {
            mlog(0,"error: unable to create a valid ASSP - UUID and License Indentifier");
        }
    }

    if (    $Config{UUID}
         && ASSP::UUID::time_of_uuid($Config{UUID}) > time + 7201
         && ASSP::UUID::is_uuid_string($Config{UUID})
         && ASSP::UUID::version_of_uuid($Config{UUID}) == 1 )
    {
        mlog(0,"error: the local time or the ASSP - UUID and License Indentifier is not valid!");
    }

    $ConfigAdd{UUID} = $Config{UUID} if $Config{UUID};
    $ConfigAdd{globalRegisterURL} = $Config{globalRegisterURL};
    $ConfigAdd{globalUploadURL} = $Config{globalUploadURL};

# -- this resets the variable name with the same name as the config key to the new value
# -- for example $Config{myName}="ASSP-nospam" -> $myName="ASSP-nospam";
    foreach (keys %Config) {${$_}=$Config{$_};}

    # set the date/time for spambox.cfg
    $asspCFGTime = $FileUpdate{"$base/spambox.cfgspamboxCfg"} = ftime("$base/spambox.cfg");

    my ($logdir, $logdirfile) = $logfile =~ /^(.*[\/\\])?(.*?)$/o;
    $blogfile = "$logdir" . "b$logdirfile";

    if ($DisableSMTPNetworking == 2) {
        $Config{DisableSMTPNetworking} = $DisableSMTPNetworking = 0;
    }

    $Config{bombError} = $bombError = $SpamError if !$bombError;

    if ($Config{inclResendLink}) {
        $fileLogging = $Config{fileLogging} = 1;
    }

    $Config{ignoreDBVersionMissMatch} = $ignoreDBVersionMissMatch = 3  # ignore DB Version Miss Match if rebuild is not used
        if (   ! $Config{spamdb}
            || ($CanUseSchedCron && $Config{RebuildSchedule} =~ /noschedule/io)
            || ! $CanUseSchedCron);

    $Config{MemoryUsageLimit} = (($Config{NumComWorkers} + 3) * 100) if ($Config{MemoryUsageLimit} && $Config{MemoryUsageLimit} < (($Config{NumComWorkers} + 3) * 100));

    # correct the DoRebuildSpamdb to RebuildSchedule

    if ($Config{DoRebuildSpamdb} && $Config{RebuildSchedule} eq 'noschedule') {
        $Config{RebuildSchedule} = '0 ' . $Config{DoRebuildSpamdb} . ' * * *';
        delete $Config{DoRebuildSpamdb};
    }

    # correct the old LogNameMMDD to LogNameDate

    if (exists $Config{LogNameMMDD} && ! exists $Config{LogNameDate}) {
        $newConfig{LogNameDate} = $Config{LogNameDate} = $Config{LogNameMMDD} ? 'MM-DD' : 'YY-MM-DD';
        delete $Config{LogNameMMDD};
    }

    # use the right regex-optimizer (Regex::Optimizer is obsolet)
    
    if ($Config{useRegexOptimizer} && ! $Config{useRegexpOptimizer}) {
        $Config{useRegexpOptimizer} = 1;
        delete $Config{useRegexOptimizer};
    }

    # limit the workernumber if BerkeleyDB is used for all hashes
    
    if ($CanUseBerkeleyDB &&
        $NumComWorkers > 15 &&
        $DBdriver =~ /BerkeleyDB/o &&
        $pbdb =~ /DB:/o &&
        $useDB4IntCache &&
        $useDB4griplist
       )
    {
        $NumComWorkers = $Config{NumComWorkers} = 15;
        mlog(0,"ATTENTION: 'NumComWorkers' was reduced to 15, because of extensive BerkeleyDB configuration");
    }

    if ($newConfig{UseUnicode4SubjectLogging} && $UseUnicode4MaillogNames) {
        $UseUnicode4SubjectLogging = $Config{UseUnicode4SubjectLogging} = 1;
        mlog(0,"adminupdate: 'UseUnicode4SubjectLogging' was set to 1, because 'UseUnicode4MaillogNames' is 1 on version upgrade");
    }
    my $savecfg = 0;
    my $savesync = 0;
    foreach (sort keys %newConfig) {
        mlog(0,"info: new config parameter $_ was set to ${$_}");
        if (&syncCanSync() && ! exists $neverShareCFG{$_}) {
            $ConfigSync{$_} = &share({});
            $ConfigSync{$_}->{sync_cfg} = 0;
            $ConfigSync{$_}->{sync_server} = &share({});
            $savesync = 1;
        }
        $savecfg = 1;
    }
    &SaveConfig() if $savecfg;
    &syncWriteConfig() if $savesync;
    %newConfig = ();

    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
        if ($c->[0] && ${$c->[0]} !~ /$c->[5]/) {
            mlog(0,"info: $c->[0] - invalid value ${$c->[0]} corrected to $c->[4]");
            ${$c->[0]} = $c->[4];
            $Config{$c->[0]} = $c->[4];
        }
    }
    $runHMMusesBDB = $HMMusesBDB;
    print "\t\t\t\t\t[OK]\n";
    # turn settings into regular expressions
    &niceConfigPos();
    &ThreadCompileAllRE(1);
}
