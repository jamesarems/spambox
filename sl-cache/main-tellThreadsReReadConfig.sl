#line 1 "sub main::tellThreadsReReadConfig"
package main; sub tellThreadsReReadConfig {
    if ($Config{inclResendLink}) {
        $Config{fileLogging} = 1;
        $fileLogging = 1;
    }
    &SaveConfig() if ($ConfigChanged < 2);
    $recompileAllRe ? &ThreadCompileAllRE(0) : &optionFilesReload();
    $recompileAllRe = 0;
    &initMaintScheduler if $ScheduleIsChanged;
    %LDAPNotFound = ();
    &ConfigOverwriteRe();
    &readNorm();
    my $delayThread = checkFileHashUpdate();
    if (! $NextConfigReload) {
        foreach my $name (keys %ConfigWatch) {
            next if $ConfigWatch{$name} eq 'delete';
            my ($s,$t,$d) = split(/,/o,$ConfigWatch{$name},3);
            $s->($name, $Config{$name}, $Config{$name}, '', $d);
        }
    }
    foreach (keys %Threads) {
        if ($HMM4ISP && $delayThread) {
            my $newDelay = $_ >= 10000 ? time + (($NumComWorkers + 1) * $threadReloadConfigDelay) + $_ - 10000 : time + $_ * $threadReloadConfigDelay;
            $ComWorker{$_}->{rereadconfig} = $newDelay if $ComWorker{$_}->{rereadconfig} < $newDelay;
        } else {
            my $newDelay = $_ >= 10000 ? time + $NumComWorkers + 1 + $_ - 10000 : time + $_;
            $ComWorker{$_}->{rereadconfig} = $newDelay if $ComWorker{$_}->{rereadconfig} < $newDelay;
        }
        threads->yield();
        next if $_ >= 10000;
        $ThreadQueue{$_}->enqueue('run') if ($ComWorker{$_}->{issleep});
        ThreadYield();
    }
    reloadGriplist();
    while (my ($k,$v) = each %ModuleWatch) {
        if (-e $v->{file} && $v->{filetime} != ftime($v->{file})) {
            mlog(0,"info: reloading module '$k' - '$v->{file}'");
            unloadNameSpace($k);
            eval "use $k";
            mlog(0,"error: can't reload module '$k' - $@") if $@;
            if (!$@ && $v->{run}) {
                eval{$v->{run}->()};
                mlog(0,"error: can't call sub '$v->{run}' in module '$k' - $@") if $@;
            }
            $ModuleWatch{$k}->{filetime} = ftime($v->{file});
        }
    }
    $ConfigChanged = 0;
    threads->yield;
}
