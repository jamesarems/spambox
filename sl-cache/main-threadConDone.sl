#line 1 "sub main::threadConDone"
package main; sub threadConDone {
    my $fhh = shift;
    return unless($fhh);
    my $fno;
    if (exists $Con{$fhh} && $Con{$fhh}->{self}) {
        $fno = fileno($Con{$fhh}->{self});
        $fno = $Con{$fhh}->{fno} if (! $fno && exists $Con{$fhh}->{fno});
    } else {
        $fno = fileno($fhh);
    }
    unpoll($fhh,$readable);
    unpoll($fhh,$writable);
    delete $SocketCalls{$fhh} if (exists $SocketCalls{$fhh});
    delete $Fileno{$fno} if (exists $Fileno{$fno});
    if (exists $ConFno{$fno}) {delete $ConFno{$fno}};
}
