#line 1 "sub main::cleanCacheSMTPdomainIP"
package main; sub cleanCacheSMTPdomainIP {
    d('cleanCacheSMTPdomainIP');
    my $ips_before= my $ips_deleted=0;
    my $ct;
    my $t=time;
    while (my ($k,$v)=each(%SMTPdomainIP)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $ips_before % 100;
        $ips_before++;

        if (($t - $SMTPdomainIPTriesExpiration{$k}) > $maxSMTPdomainIPExpiration) {
            $ips_deleted++;
            delete $SMTPdomainIP{$k};
            delete $SMTPdomainIPTries{$k};
            delete $SMTPdomainIPTriesExpiration{$k};
        }
    }
    mlog(0,"SMTPdomainIP: cleaning cache finished: domain\'s before=$ips_before, deleted=$ips_deleted") if  $MaintenanceLog && $ips_before > 0;
}
