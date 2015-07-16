#line 1 "sub main::fillPortArray"
package main; sub fillPortArray {
    my ($listen, $new) = @_;
    return unless $listen;
    @{$listen} = ();
    return unless $new;
    my ($interface,$p);
    if ($new=~/\|/o) {
        foreach my $portA (split(/\|/o, $new)) {
            ($interface,$p)=$portA=~/^(.*):([^:]*)$/o;
            $interface =~ s/\s//go;
            $p =~ s/\s//go;
            $portA =~ s/\s//go;
            if ($interface) {
                push @{$listen}, "$interface:$p";
            } else {
                push @{$listen}, "0.0.0.0:$portA";
                push @{$listen}, "[::]:$portA" if $CanUseIOSocketINET6;
            }
        }
    } else {
        ($interface,$p)=$new=~/(.*):([^:]*)/o;
        $interface =~ s/\s//go;
        $p =~ s/\s//go;
        $new =~ s/\s//go;
        if ($interface) {
            push @{$listen}, "$interface:$p";
        } else {
            push @{$listen}, "0.0.0.0:$new";
            push @{$listen}, "[::]:$new" if $CanUseIOSocketINET6;
        }
    }
}
