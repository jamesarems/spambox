#line 1 "sub main::setBSRE"
package main; sub setBSRE {
    my (@uad, @u, @d);
    foreach my $ad (split(/\|/o,$_[0])) {
        if($ad=~/\S\@\S/o) {
            push(@uad,$ad);
        } elsif( $ad=~/^\@/o ) {
            push(@d,$ad);
        } else {
            push(@u,$ad);
        }
    }
    my @s;
    push(@s,'^\s*$'); # null sender address
    push(@s,'^(?:'.join('|',@uad).')$') if @uad;
    push(@s,'^(?:'.join('|',@u).')@') if @u;
    push(@s,'(?:'.join('|',@d).')$') if @d;
    my $s=join("|",@s);
    $s =~ s/\@/\\\@/go;
    $s='<not a valid list>' unless $s;
    SetRE('BSRE',$s,
          $regexMod,
          'Bounce Senders',$_[1]);
}
