#line 1 "sub main::matchHashKey"
package main; sub matchHashKey {
    my ($hash, $key, $wantkey) = @_;
    return unless $hash;
    return unless $key;

    my ($start,$end);
    my $v = undef;
    my $rkey = undef;
    my $l;
#    mlog(0,"matchHashKey wantkey: <$wantkey>") if $WorkerNumber == 0;
    ($wantkey,$start,$end) = split(/\s+/o,$wantkey);
#    mlog(0,"matchHashKey start end wantkey: <$start> <$end> <$wantkey>") if $WorkerNumber == 0;
    foreach my $k (keys %{$hash}) {
        $l = length($k) if $l < length($k);
    }
    foreach my $k (sort {(' ' x ($l - length($main::b)).$main::b) cmp (' ' x ($l - length($main::a)).$main::a)} keys %{$hash}) {
        $rkey = $k;
        $v = ${$hash}{$k};
        last if lc($key) eq lc($k);
        $k =~ s/(^|[^\\])\.($|[^\*\?\{])/$1\\.$2/go;    # escape a single unescaped and unquatified dot
        $k =~ s/(^|[^*()\]\\])\?/$1\.\?/go;             # replace an unescaped ? with .? if it is not a quantifier
        $k =~ s/(^|[^)\].\\])\*/$1\.\*\?/go;            # replace an unescaped * with .*? if it is not a quantifier
        if ($start && $end) {
#            mlog(0,"matchHashKey_s_e: $key $k") if $WorkerNumber == 0;
            last if eval{$key =~ /^$k$/i;};
        } elsif ($start) {
#            mlog(0,"matchHashKey_s: $key $k") if $WorkerNumber == 0;
            last if eval{$key =~ /^$k/i;};
        } elsif ($end) {
#            mlog(0,"matchHashKey_e: $key $k") if $WorkerNumber == 0;
            last if eval{$key =~ /$k$/i;};
        } else {
#            mlog(0,"matchHashKey: $key $k") if $WorkerNumber == 0;
            last if eval{$key =~ /$k/i;};
        }
        mlog(0,"warning: regex error in generic hash ($hash) key ($key) match - $@") if $@;
        $rkey = $v = undef;
    }
    return $v unless $wantkey;
    return $rkey if $wantkey == 1;
    return ($rkey, $v);
}
