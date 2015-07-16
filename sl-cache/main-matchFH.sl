#line 1 "sub main::matchFH"
package main; sub matchFH {
    my ($fh, @fhlist) = @_;
    return 0 unless scalar @fhlist;
    return 0 unless $fh;
    my $sinfo;
    if (exists $Con{$fh} && $Con{$fh}->{localip} && $Con{$fh}->{localport}) {
        $sinfo = $Con{$fh}->{localip} . ':' . $Con{$fh}->{localport};
    }
    $sinfo ||= $fh->sockhost() . ':' . $fh->sockport();
    $sinfo =~ s/:::/\[::\]:/o;

    while (@fhlist) {
        my $lfh = shift @fhlist;
        if ($lfh =~ /^(?:0\.0\.0\.0|\[::\])(:\d+)$/o) {
            my $p = $1;
            return 1 if ($sinfo =~ /$p$/);
        }
        return 1 if ($sinfo eq $lfh);
    }
    return 0;
}
