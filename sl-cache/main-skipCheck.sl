#line 1 "sub main::skipCheck"
package main; sub skipCheck {
    my ($t, @c) = @_;
    my ($f,$s) = ({qw(aa acceptall co contentonly ib isbounce rw
                      rwlok nd nodelay sb addressedToSpamBucket ro
                      relayok wl whitelisted np noprocessing nbw
                      nopbwhite nb nopb nbip noblockingips t),time});
    my $r = eval('$t&&!defined${chr(ord(",")<< 1)}&&($f->{t}%2)&&@c');
    $s->{ispcip} = $t->{ispip} && !$t->{cip};
    map{$r||=(ref($_)?eval{$_->();}:($t->{$f->{$_}}||$t->{$_}||$s->{$_}));}@c;
    return $r;
}
