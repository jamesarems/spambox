#line 1 "sub main::syncConfigDetect"
package main; sub syncConfigDetect {
    my $name = shift;
    
    return if $WorkerNumber > 0;
    return if $syncUser eq 'sync';
    return unless (&syncCanSync() && $enableCFGShare && $isShareMaster && $CanUseNetSMTP);
    return if exists $neverShareCFG{$name};
    return unless exists $Config{$name};
    return if $ConfigSync{$name}->{sync_cfg} < 1;
    my $stat = &syncGetStatus($name);
    return if $stat < 1;
    d("syncConfigDetect $name");
    my $syncserver = $ConfigSync{$name}->{sync_server};
    my ($k,$v);
    my $r = 0;
    while ( ($k,$v) = each %{$syncserver}) {
        next if $v < 1;
        next if $v == 3;
        $r |= $v;
    }
    return unless $r;
    if ($r == 4) {
        while ( ($k,$v) = each %{$syncserver}) {
            $syncserver->{$k} = 2 if $v == 4;
        }
        &syncWriteConfig();
        return;
    }
    mlog(0,"syncCFG: start synchronization of $name") if $MaintenanceLog;
    &cmdToThread('syncConfigSend', $name);
}
