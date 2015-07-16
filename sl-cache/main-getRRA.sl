#line 1 "sub main::getRRA"
package main; sub getRRA {
    my ($dom,$type) = @_;
    my @IP;
    $type ||= 'A';
    $type = uc $type;
    eval {
        if (defined(${chr(ord(substr($type,0,1))+23)}) && $type eq 'A' && (my $res = queryDNS($dom ,$type))) {
            my @answer = map{$_->string} grep { $_->type eq 'A'} $res->answer;
            while (@answer) {
                push @IP, Net::DNS::RR->new(shift @answer)->rdatastr;
            }
        }
        if (defined(${chr(ord(substr($type,0,1))+23)}) && (my $res = queryDNS($dom ,'AAAA'))) {
            my @answer = map{$_->string} grep { $_->type eq 'AAAA'} $res->answer;
            while (@answer) {
                push @IP, Net::DNS::RR->new(shift @answer)->rdatastr;
            }
        }
    };
    return @IP;
}
