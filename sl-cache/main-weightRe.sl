#line 1 "sub main::weightRe"
package main; sub weightRe {
    my ($valence,$name,$kk,$fh) = @_;
    my $key = ref $kk ? $$kk : $kk;                                          # bombs, ptr, helo only
    my $this = ($fh && defined $Con{$fh} && $name =~ /bomb|script|black|Reversed|Helo/o) ? $Con{$fh} : undef;
    my $cvalence;
    my $weight;
    my $found;
    my $count = 0;
    my @WeightRE = @{$name.'WeightRE'};
    while (@WeightRE) {
        my $k = shift @WeightRE;
        $k =~ s/^\{([^\}]*)\}(.*)$/$2/os;
        my $how = $1 ? $1 : '';
        ++$count and next unless $k;

        if ($how && $this) {
            ++$count and next if ($this->{noprocessing}  && $how =~ /[nN]\-/o);
            ++$count and next if ($this->{whitelisted}   && $how =~ /[wW]\-/o);   #never
            ++$count and next if ($this->{relayok}       && $how =~ /[lL]\-/o);
            ++$count and next if ($this->{ispip}         && $how =~ /[iI]\-/o);

            ++$count and next if (!$this->{noprocessing} && $how =~ /[nN]\+/o);
            ++$count and next if (!$this->{whitelisted}  && $how =~ /[wW]\+/o);   #only
            ++$count and next if (!$this->{relayok}      && $how =~ /[lL]\+/o);
            ++$count and next if (!$this->{ispip}        && $how =~ /[iI]\+/o);
        }

        if ($this && $name =~ /bomb|script|black/o) {   # bombs
            ++$count and next if (!$bombReNP    && $this->{noprocessing}  && $how !~ /[nN]\+?/o);
            ++$count and next if (!$bombReWL    && $this->{whitelisted}   && $how !~ /[wW]\+?/o);   #config
            ++$count and next if (!$bombReLocal && $this->{relayok}       && $how !~ /[lL]\+?/o);
            ++$count and next if (!$bombReISPIP && $this->{ispip}         && $how !~ /[iI]\+?/o);
        }

        if ($this && $name =~ /Reversed/o) {         # ptr
            ++$count and next if (!$DoReversedNP    && $this->{noprocessing}  && $how !~ /[nN]\+?/o);
            ++$count and next if (!$DoReversedWL    && $this->{whitelisted}   && $how !~ /[wW]\+?/o);   #config
        }

        if ($this && $name =~ /Helo/o) {             # helo
            ++$count and next if (!$DoHeloNP    && $this->{noprocessing}  && $how !~ /[nN]\+?/o);
            ++$count and next if (!$DoHeloWL    && $this->{whitelisted}   && $how !~ /[wW]\+?/o);   #config
        }

        if ($key =~ /$k/is) {
            $weight = ${$name.'Weight'}[$count];
            $found = 1;
            mlog(0,"info: weighted regex ($name) result found for $key - with $k - weight is $weight") if $regexLogging;
            $weightMatch .= ' , ' if $weightMatch;
            $weightMatch .= $k;
            last;
        }
        $count++;
    }

    $valence = ${$valence}[0] if $valence =~ /ValencePB$/o;
    return $valence unless $found;
    eval{$cvalence = int($valence * $weight);};
    return $valence if $@;
    return $cvalence if abs($weight) <= 6;
    return $weight;
}
