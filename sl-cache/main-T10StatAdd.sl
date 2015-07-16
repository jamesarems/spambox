#line 1 "sub main::T10StatAdd"
package main; sub T10StatAdd {
    my $fh = shift;
    return unless $fh;
    return if $Con{$fh}->{type} != 'C';
    return if $Con{$fh}->{timedout};
    return if ($Con{$fh}->{error} !~ /^[45]/o  &&
               $Con{$fh}->{prepend} !~ /$SpamTagRE|\[PersonalBlack\]|\[PenaltyDelay\]/io);
    my $ip = $Con{$fh}->{ispip} && $Con{$fh}->{cip} ? $Con{$fh}->{cip} : $Con{$fh}->{ip};
    my $t = time;
    if ($ip) {
        $T10StatI{$ip}++;
        $T10StatT{$ip} = $t;
    }
    if ($Con{$fh}->{mailfrom}) {
        $T10StatS{lc $Con{$fh}->{mailfrom}}++;
        $T10StatT{lc $Con{$fh}->{mailfrom}} = $t;
    }
    if ((lc $Con{$fh}->{mailfrom}) =~ /\@([^@]+)$/o) {
        $T10StatD{$1}++;
        $T10StatT{$1} = $t;
    }
    my %rcpt;
    foreach (split(/\s+/o,$Con{$fh}->{rcpt})) {
        $rcpt{lc $_} = 1 if $_;
    }
    foreach (keys %rcpt) {
        $T10StatR{$_}++;
        $T10StatT{$_} = $t;
    }
}
