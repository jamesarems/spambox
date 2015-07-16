#line 1 "sub main::cmdToThread"
package main; sub cmdToThread {
    my ($sub,$parm) = @_;
    my $i;
    {
        lock(%cmdQParm) if is_shared(%cmdQParm);
        do {
            $i = Time::HiRes::time();
        } while (exists $cmdQParm{$i});
        $cmdQParm{$i} = ref($parm) ? $$parm : $parm;
    }
    mlog(0,"info: queued command '$sub' to MaintThread") if $MaintenanceLog >= 2;
    threads->yield;
    $cmdQueue->enqueue("sub($sub)$i");
    threads->yield;
}
