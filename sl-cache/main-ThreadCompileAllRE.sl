#line 1 "sub main::ThreadCompileAllRE"
package main; sub ThreadCompileAllRE {
    my $init = shift;
    my %configOFiles = (       # possibly option files that have to be registered
        'ConfigMakeRe' => 1,
        'ConfigMakeLocalDomainsRe' => 1,
        'ConfigMakePrivatRe' => 1,
        'ConfigMakeSLRe' => 1,
        'ConfigMakeSLReSL' => 1,
        'ConfigMakeIPRe' => 1,
        'ConfigMakeGroupRe' => 1,
        'configUpdateRBLSP' => 1,
        'configUpdateURIBLSP' => 1,
        'configUpdateRWLSP' => 1,
        'updateDNS' => 1,
        'configUpdateASSPCfg' => 1,
        'configUpdateDKIMConf' => 1,
        'configChangeRcptRepl' => 1,
        'ConfigCompileRe' => 1,
        'ConfigCompileNotifyRe' => 1,
        'configUpdateCCD' => 1,
        'configUpdateCA' => 1,
        'configUpdateSPFOF' => 1,
        'configChangeMSGIDSec' => 1,
        'configChangeBATVSec' => 1,
        'configUpdateBACKSctrSP' => 1,
        'configChangeIC' => 1,
        'configChangeOC' => 1,
        'configChangeProxy' => 1,
        'ConfigChangeSyncFile' => 1,
        'configChangeRT' => 1,
        'configUpdateMaxSize' => 1,
        'configUpdateStringToNum' => 1,
        'configChangeConfigSched' => 1,
        'updateUserAttach' => 1,
        'ConfigMakeEmailAdmDomRe' => 1,
        'configChangeLocalIPMap' => 1
    );
    my %initConfig = (               #     config parms that have to be inititalized anyway
        'BadAttachL1' => 'Initializing',
        'GoodAttach' => 'Initializing',
        'ValidateRBL' => 'Initializing',
        'ValidateRWL' => 'Initializing',
        'ValidateURIBL' => 'Initializing',
        'EnableSRS' => 'Initializing',
        'freqNonSpam' => 'Initializing',
        'freqSpam' => 'Initializing',
        'NoTLSlistenPorts' => 'Initializing',
        'NoAUTHlistenPorts' => 'Initializing',
        'TLStoProxyListenPorts' => 'Initializing',
        'MaxAllowedDups' => 'Initializing',
        'POP3ConfigFile' => 'Initializing',
        'asspCpuAffinity' => 'Initializing'
    );
    @PossibleOptionFiles=();
    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
        next if @{$c}==5; # skip headings
        if ($WorkerNumber > 0 && $WorkerNumber < 1000) {
            undef $c->[2] if $c->[2];
            undef $c->[3] if $c->[3];
            undef $c->[4] if $c->[4];
            undef $c->[5] if $c->[5];
            undef $c->[7] if $c->[7];
        }
        next if (! $c->[6]);

        if (   exists $configOFiles{$c->[6]}  # are there possibly option files - register them
            || exists $PluginFiles{$c->[0]}   # are there possibly plugin option files - register them
           )
        {
            push(@PossibleOptionFiles,[$c->[0],$c->[1],$c->[6]]);
            mlog(0,"ERROR: possible code or language file error in config for $c->[0] - '*' not found at the end of the small description") if ($c->[1] !~ /\*\s*$/o && $WorkerNumber == 0);
            mlog(0,"ERROR: possible code or language file error in config for $c->[0] - '**' not found at the end of the small description for weighted RE") if (exists $WeightedRe{$c->[0]} && $c->[1] !~ /\*\*\s*$/o && $WorkerNumber == 0);
        } elsif ($c->[0] ne 'POP3ConfigFile') {
            mlog(0,"ERROR: possible code error in sub 'ThreadCompileAllRE' for $c->[0] - option file is not checked") if ($c->[1] =~ /\*$/o && $WorkerNumber == 0);
        }

        if ($c->[0] =~ /ValencePB$/o && defined $c->[6]) {     # initialize the Valence configuration values
            $c->[6]->($c->[0],$Config{$c->[0]},$Config{$c->[0]},$init);
        }

        if (exists $initConfig{$c->[0]}) {     # there are config parms that have to be inititalized anyway
            d("call to $c->[6]->($c->[0],'',$Config{$c->[0]},$initConfig{$c->[0]})");
            $c->[6]->($c->[0],'',$Config{$c->[0]},$initConfig{$c->[0]});
        }
    }
    push(@PossibleOptionFiles,['TLDS','TOP level Domains',\&ConfigCompileRe]);
    push(@PossibleOptionFiles,['BlockReportFile','File for Blockreportrequest',\&initMaintScheduler]) if $BlockReportFile;

    # Unicode:Normalize is loaded there
    ConfigChangeNormUnicode('normalizeUnicode','',$Config{normalizeUnicode}, 'Initializing') if exists $ComWorker{$WorkerNumber} && $ComWorker{$WorkerNumber}->{recompileAllRe};
    
    for my $idx (0...$#PossibleOptionFiles) {
        my $f = $PossibleOptionFiles[$idx];
        next if ($f->[0] eq 'asspCfg');
        if ($init || (((exists $ComWorker{$WorkerNumber} && $ComWorker{$WorkerNumber}->{recompileAllRe}) || $recompileAllRe) && $f->[2] eq 'ConfigCompileRe')) {
            $f->[2]->($f->[0],'',$Config{$f->[0]},'Initializing',$f->[1]);
        } else {
            if (($Config{$f->[0]} =~ /^ *file: *(.+)/io && fileUpdated($1,$f->[0])) or
                $Config{$f->[0]} !~ /^ *file: *(.+)/io or
                exists $ConfigWatch{$f->[0]})
            {
               $f->[2]->($f->[0],$Config{$f->[0]},$Config{$f->[0]},'',$f->[1]);
            }
        }
    }
    $ComWorker{$WorkerNumber}->{recompileAllRe} = 0 if exists $ComWorker{$WorkerNumber};
    $recompileAllRe = 0;  # really exists only in MainThread

    $spamSubjectEnc = is_7bit_clean(\$spamSubject) ? $spamSubject : encodeMimeWord($spamSubject,'B','UTF-8');
    &threadCheckConfig() if $threadCheckConfig;
    &checkFileHashUpdate() unless $init;
}
