#line 1 "sub main::ThreadReReadConfig"
package main; sub ThreadReReadConfig {
    my $Iam = shift;
    threads->yield;
    &ThreadCompileAllRE(0);
    &ConfigOverwriteRe();
    threads->yield();
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
    $ComWorker{$Iam}->{rereadconfig} = 0;
    threads->yield;
    mlog(0,"$WorkerName finished reloading configuration") if ($WorkerLog);
    $MinPollTimeT =  $MinPollTime ? $MinPollTime : 1 ;
}
