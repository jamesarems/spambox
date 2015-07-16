#line 1 "sub main::cleanCacheURI"
package main; sub cleanCacheURI {
    d('cleanCacheURI');
    my $domains_before= my $domains_deleted=0;
    my $t=time;
    my $ct;my $status;my @sp;
    my $maxtime1 = $URIBLCacheIntervalMiss*3600*24;
    my $maxtime2 = $URIBLCacheInterval*3600*24;
    while (my ($k,$v)=each(%URIBLCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $domains_before % 100;
        ( $ct, $status, @sp ) = split( ' ', $v );

        $domains_before++;
        if ($status==2 && $t-$ct>=$maxtime1) {
            delete $URIBLCache{$k};
            $domains_deleted++;
            next;
        }
        if ($t-$ct>=$maxtime2) {
            delete $URIBLCache{$k};
            $domains_deleted++;
            next;
        }
        next if $status == 2;
        my $spstr = join(' ',@sp);
        foreach my $sp (@sp) {
            my $tsp = $sp;
            $tsp =~ s/([^\<]+).*/$1/o;
            next if grep(/$tsp/i,@uribllist);
            $spstr =~ s/ ?$sp//ig;
        }
        if ($spstr) {
            $URIBLCache{$k} = "$ct $status $spstr";
        } else {
            delete $URIBLCache{$k};
            $domains_deleted++;
        }
    }
    mlog(0,"URIBLCache: cleaning cache finished: Domains before=$domains_before, deleted=$domains_deleted") if  $MaintenanceLog && $domains_before != 0;
    if ($domains_before==0) {
        %URIBLCache=();
        if ($pbdb =~ /DB:/o && ! $failedTable{URIBLCache}) {
        } else {
            &SaveHash('URIBLCache');
        }
    }
}
