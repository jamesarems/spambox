#line 1 "sub RBL::decode_packet"
package RBL; sub decode_packet {
    # takes a raw DNS response packet
    # returns domain, response
    my ($self,$data) = @_;
    my $packet = Net::DNS::Packet->new(\$data);
    return ('','','INVALID') unless ($packet);
    my $headerid = $packet->header->id;
    return ('','','INVALID') unless (grep {$_ == $headerid} @{$self->{ID}});
    my @answer = eval{$packet->answer};
    my @question = eval{$packet->question};
    my $domain = eval{$question[0]->qname};
    $domain =~ s/^.*?$main::IPRe\.//o;
    if (@answer && eval{$packet->header->rcode} ne 'NXDOMAIN') {
        my(%res, $res, $type);
        foreach my $answer (@answer) {
            next unless ref $answer;
            $type = $answer->type;
            $res{$type} = $type eq 'A'     ? inet_ntoa($answer->rdata)  :
                          $type eq 'CNAME' ? cleanup($answer->rdata)    :
                          $type eq 'TXT'   ? (exists $res{'TXT'} && $res{'TXT'}.'; ')
                                             . eval{$answer->txtdata;}  :
                          '?';
        }
        $res = $res{'A'} || $res{'CNAME'} || $res{'TXT'};
        $self->{ txt }{ $domain } .= $res{'TXT'} if $res{'TXT'};
        ($res) = $res =~ /(127\.\d+\.\d+\.\d+)/os;
        return $domain, $res, $type if $res;
    }

    # OK, there were no answers -
    # need to determine which domain
    # sent the packet.

    return $domain;
}
