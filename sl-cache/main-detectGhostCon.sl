#line 1 "sub main::detectGhostCon"
package main; sub detectGhostCon {
    return unless $FreeupMemoryGarbage;
    my $count = 0;
    my $mem = 0;
    my $what;
    while ( my ($fh,$dummy) = each %Con) {
        next if $fh && exists $WebConH{$fh};
        next if $fh && exists $StatConH{$fh};
        next if $fh && exists $repollFH{$fh};
        if  (! $fh) {
           mlog(0,"error: detected unexpected garbage in the memory - please report to development") if $fh eq '0';
           delete $ConDelete{$fh};
           delete $SocketCalls{$fh};
           while (my ($k,$v) = each %{$Con{$fh}}) {
                if (ref($v) eq 'ARRAY') {
                    $v .= " @{$v}";
                } elsif (ref($v) eq 'HASH') {
                    while (my ($k1,$v1) = each %{$v}) {
                        $v .= " , '$k1,$v1'";
                    }
                }
                eval{$mem += length($v) + 8;};
                mlog(0,"info: memory garbage in : fh=$fh , key=$k , value=$v") if $MaintenanceLog > 2;
           }
           &printallCon($fh) if ($MaintenanceLog >= 2);
           $count++;
           delete $Con{$fh};
           delete $WebConH{$fh};
           delete $StatConH{$fh};
           next;
        }
        next if (fileno($Con{$fh}->{self}));
        next if $IOEngineRun == 0 && $readable->[3]{$fh};
        next if $IOEngineRun == 0 && $writable->[3]{$fh};
        next if (exists $ConDelete{$fh});
        next if ($Con{$fh}->{timestart} + 3600 > time);
        while (my ($k,$v) = each %{$Con{$fh}}) {
            if (ref($v) eq 'ARRAY') {
                $v .= " @{$v}";
            } elsif (ref($v) eq 'HASH') {
                while (my ($k1,$v1) = each %{$v}) {
                    $v .= " , '$k1,$v1'";
                }
            }
            eval{$mem += length($v) + 8;};
            mlog(0,"info: memory garbage in : fh=$fh , key=$k , value=$v") if $MaintenanceLog > 2;
        }
        $count++;
        &printallCon($fh) if ($MaintenanceLog >= 2);
        if ($WorkerNumber > 0) {
            &done2($fh);      # MainThread (Worker_0) never closes SMTP sockets here
            $what = 'SMTP';
        } else {
            unpoll($fh,$readable);
            unpoll($fh,$writable);
            delete $Con{$fh};
            delete $ConDelete{$fh};
            delete $SocketCalls{$fh};
            $what = 'SMTP and WEB';
        }
    }
    undef %Con unless keys(%Con);
    undef %ConDelete unless keys(%ConDelete);
    undef %SocketCalls unless keys(%SocketCalls);
    undef %repollFH unless keys(%repollFH);
    undef %WebConH unless keys(%WebConH);
    undef %MainLoopInWebFH unless keys(%MainLoopInWebFH);
    undef %StatConH unless keys(%StatConH);
    $mem = int(($count*128 + $mem)/1024 + 2);
    mlog(0,"info: cleaned $mem kbyte of memory from $count closed $what connections") if ($count && ($MaintenanceLog >= 2 or $ConnectionLog >= 2));
}
