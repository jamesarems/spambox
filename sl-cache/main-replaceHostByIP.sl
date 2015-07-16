#line 1 "sub main::replaceHostByIP"
package main; sub replaceHostByIP {
    my ($new,$name,$description) = @_;
    my @nnew;
    my $ret;
    my $minTTL = 999999999;
    foreach my $l (split(/\|/o,$$new)) {
        $l =~ s/^\s+//o;
        $l =~ s/\s$//o;
        if ($l =~ m/^$IPv6Re(?:\/\d{1,3})?/io) {  # is a IPv6 address
            push @nnew, $l;
            next;
        }
        $l =~ s/^(\d{1,3})(\s+.+)?$/$1\.$2/o;
        if ($l =~ m/^(?:\d{1,3}\.){1,3}(?:\d{1,3})?(?:\/\d{1,2})?/o) { # is a IPv4 fragment or address
            push @nnew, $l;
            next;
        }
        # found a hostname - replace it with all available IP's and remind the separator
        my ($sl,$sep,$desc) = split(/(\s*\=\>\s*|\s+)/o,$l,2);
        $sep =~ s/\s+/ /go;
        if ($sl !~ /$EmailDomainRe|\w\w+/o) {      # not a valid hostname
            $ret .= ConfigShowError(1, "AdminInfo: '$sl' is not a valid hostname or IP in $name - ignore entry");
            next;
        }
        $desc = $desc ? "$sep$desc" : " $sl";
        my $res4 = queryDNS($sl ,'A');
        my $res6 = queryDNS($sl ,'AAAA');
        if (ref($res4) || ref($res6)) {
            my @answer;
            push @answer , eval{map{$_->string} grep { $_->type eq 'A'} $res4->answer} if ref($res4);
            push @answer , eval{map{$_->string} grep { $_->type eq 'AAAA'} $res6->answer} if ref($res6);
            my $w = 1;
            while (@answer) {
                my $RR = Net::DNS::RR->new(shift @answer);
                my $ttl = eval{$RR->ttl};
                my $data = eval{$RR->rdatastr};
                $ret .= ConfigShowError(1, "AdminInfo: warning - TTL for '$sl' is only $ttl seconds in configuration of '$name' - minimum config reload interval is $host2IPminTTL seconds") if $ttl < $host2IPminTTL && $w;
                if ($data =~ /^$IPv4Re$/o) {
                    push @nnew, "$data/32$desc";
                    mlog(0,"added IP '$data/32' (TTL=$ttl) for hostname '$sl' to $name") if $WorkerNumber == 0 and $MaintenanceLog > 2;
                } elsif ($data =~ /^$IPv6Re$/o) {
                    push @nnew, "$data/128$desc";
                    mlog(0,"added IP '$data/128' (TTL=$ttl) for hostname '$sl' to $name") if $WorkerNumber == 0 and $MaintenanceLog > 2;
                } else {
                    mlog(0,"resolved record '$data' (no IP) for hostname '$sl' in $name") if $WorkerNumber == 0 and $MaintenanceLog > 2;
                }
                d("replaceHostByIP record: $sl -> $data , TTL -> $ttl");
                $w = 0 if $ttl;
                $minTTL = $ttl if $ttl < $minTTL;
            }
        } else {
            $ret .= ConfigShowError(1, "AdminInfo: error - unable to resolve IP for hostname '$sl' in configuration of '$name'");
        }
    }
    if ($WorkerNumber == 0) {
        $minTTL = $host2IPminTTL if $minTTL < $host2IPminTTL;
        if ($minTTL < 999999999) {
            $ret .= ConfigRegisterConfigWatch($name,[caller(unpack("A1",$X)-1)]->[unpack("A1",$X)+1],$minTTL,$description);
        } elsif ($ConfigWatch{$name} eq 'delete') {
            delete $ConfigWatch{$name};
        } else {
            $ConfigWatch{$name} = 'delete';
        }
    }
    $$new = join('|',@nnew);
    return $ret;
}
