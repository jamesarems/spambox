#line 1 "sub main::matchHashVal"
package main; sub matchHashVal {
    my ($hash, $val) = @_;
    return unless $hash;
    return unless $val;

    my $v = undef;
    my $ret = undef;

    foreach my $k (sort {${$hash}{$main::b} <=> ${$hash}{$main::a}} keys %$hash) {
        $ret = $k;
        $v = ${$hash}{$k};
        last if lc($val) eq lc($v);
        $v =~ s/(^|[^\\])\./$1\\./go;
        $v =~ s/(^|[^()\]])\?/$1\.\?/go;
        $v =~ s/(^|[^)\]])\*/$1\.\*\?/go;
        last if eval{$val =~ /$v/i;};
        mlog(0,"warning: regex error in generic hash ($hash) value ($val) match - $@") if $@;
        $ret = undef;
    }
    return $ret;
}
