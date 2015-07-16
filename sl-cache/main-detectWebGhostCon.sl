#line 1 "sub main::detectWebGhostCon"
package main; sub detectWebGhostCon {
    return unless $FreeupMemoryGarbage;
    my $count = 0;
    my $mem = 0;
    my %tCon = ();

    while ( my ($fh,$v) = each %WebConH) {
        $tCon{$fh} = $v;
    }
    while ( my ($fh,$v) = each %StatConH) {
        $tCon{$fh} = $v;
    }

    while ( my ($fh,$v) = each %tCon) {
        if  (! $fh) {
           eval{$mem += length($WebCon{$fh}) + 8;};
           eval{$mem += length($StatCon{$fh}) + 8;};
           $count++;
           delete $WebCon{$fh};
           delete $StatCon{$fh};
           delete $SocketCalls{$fh} if (exists $SocketCalls{$fh});
           mlog(0,"info: found \$fh == '$fh' in closed web connections") if $MaintenanceLog >= 2;
           next;
        }
        $fh = $WebConH{$fh} if $WebConH{$fh};
        $fh = $StatConH{$fh} if $StatConH{$fh};
        next if (fileno($fh));
        next if (exists $ConDelete{$fh});
        eval{$mem += length($WebCon{$fh}) + 8;};
        eval{$mem += length($StatCon{$fh}) + 8;};
        $count++;
        &WebDone($fh);
        delete $WebCon{$fh};
        delete $StatCon{$fh};
        delete $WebConH{$fh};
        delete $StatConH{$fh};
        delete $Con{$fh};
        delete $SocketCalls{$fh} if (exists $SocketCalls{$fh});
    }
    undef %Con unless keys(%Con);
    undef %ConDelete unless keys(%ConDelete);
    undef %SocketCalls unless keys(%SocketCalls);
    undef %repollFH unless keys(%repollFH);
    undef %WebConH unless keys(%WebConH);
    undef %MainLoopInWebFH unless keys(%MainLoopInWebFH);
    undef %StatConH unless keys(%StatConH);
    undef %WebIP unless keys(%WebIP);
    $mem = int(($count*128 + $mem)/1024 + 2);
    mlog(0,"info: cleaned $mem kbyte of memory from $count closed web connections") if $count && $MaintenanceLog >= 2;
}
