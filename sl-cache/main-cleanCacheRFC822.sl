#line 1 "sub main::cleanCacheRFC822"
package main; sub cleanCacheRFC822 {
    d('cleanCacheRFC822');
    my $dom_before= my $dom_deleted=0;
    my $ct;
    my $t=time;
    while (my ($k,$v)=each(%RFC822dom)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $dom_before % 100;
        $dom_before++;

        if ($t-$v>=3600) {   # 3600
            delete $RFC822dom{$k};
            $dom_deleted++;
        }
    }
    mlog(0,"RFC822dom: cleaning cache finished: domains\'s before=$dom_before, deleted=$dom_deleted") if  $MaintenanceLog && $dom_before > 0;
    if ($dom_before==0) {
        %RFC822dom=();
    }
}
