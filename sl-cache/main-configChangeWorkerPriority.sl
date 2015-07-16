#line 1 "sub main::configChangeWorkerPriority"
package main; sub configChangeWorkerPriority {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: Worker priority updated from '$old' to '$new'") unless ($init || $new eq $old);

    if ($CanUseThreadState) {
        $Config{WorkerCPUPriority} = $WorkerCPUPriority = $new;
        for (my $i = 1; $i <= $NumComWorkers; $i++) {
           my $po = $Threads{$i}->priority($WorkerCPUPriority);
           my $pn = $Threads{$i}->priority;
           $po = 0 if (! $po);
           $pn = 0 if (! $pn);
           mlog(0,"info: CPU priority changed for Worker_$i from $po to $pn") if ($po != $pn);
        }
        return '';
    }
    return "<span class=\"negative\"> - module Thread\:\:State version 0.09 is required!</span>";
}
