#line 1 "sub RBL::mk_packet"
package RBL; sub mk_packet {
    # pass me a REVERSED dotted quad ip (qip) and a blocklist domain
    my($self, $qip, $list) = @_;
    my ($packet, $txt_packet, $error);
    my $fqdn;
    if ($list =~ s/\$DATA\$/$qip/io) {     # if a key is required it is in $list
        $fqdn = $list;                    # like key.$DATA$.serviceProvider
    } else {
        $fqdn = "$qip.$list";
    }
    ($packet, $error) = Net::DNS::Packet->new( $fqdn , 'A');
    return "Cannot build DNS query for $fqdn, type A: $error" unless $packet;
    push @{$self->{ID}}, $packet->header->id;
    return $packet->data unless wantarray;
    ($txt_packet, $error) = Net::DNS::Packet->new($fqdn, 'TXT', 'IN');
    return "Cannot build DNS query for $fqdn, type TXT: $error" unless $txt_packet;
    push @{$self->{ID}}, $packet->header->id;
    $packet->data, $txt_packet->data;
}
