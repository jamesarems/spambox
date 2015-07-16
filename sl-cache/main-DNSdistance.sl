#line 1 "sub main::DNSdistance"
package main; sub DNSdistance {
    my $DNSResponseTime = shift;
    my $nameservers = shift;
    return ($_[0] & 0) unless @$nameservers;
    my @server = getNameserver(@$nameservers);
    return ($_[0] & 0) unless @server;
    my %distance;
    foreach my $i (@server) {
        next unless $i;
        foreach my $j (@server) {
            next unless $j;
            next if ($i eq $j);
            $distance{"$i-$j"} = $DNSResponseTime->{$i} - $DNSResponseTime->{$j};
            mlog(0,"info: DNS-distance $i-$j = ".$distance{"$i-$j"}) if ($MaintenanceLog > 2 && $DNSResponseLog);
        }
    }
    my %newdistance = %distance;
    my %olddistance = %DNSRespDist;
    foreach (keys %olddistance) {
        if (! exists $newdistance{$_}) {
            mlog(0,"info: new distance $_  not found") if ($MaintenanceLog > 2 && $DNSResponseLog);
            %DNSRespDist = %distance;
            return $_[0];
        }
        delete $newdistance{$_};
    }
    if (scalar keys %newdistance) {
        mlog(0,"info: new distance list is longer than the previouse") if ($MaintenanceLog > 2 && $DNSResponseLog);
        %DNSRespDist = %distance;
        return $_[0];
    }
    %newdistance = %distance;
    foreach (keys %newdistance) {
        if (abs($newdistance{$_} - $olddistance{$_}) > $maxDNSRespDist) { # too large DNS server response time distance change
            if ($MaintenanceLog > 2 && $DNSResponseLog) {
                my $val = abs($newdistance{$_} - $olddistance{$_});
                mlog(0,"info: distance $_ changed by $val ms (max is $maxDNSRespDist ms)");
            }
            %DNSRespDist = %distance;
            return $_[0];
        }
    }
    %DNSRespDist = %distance;
    return ($_[0] & 0);
}
