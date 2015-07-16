#line 1 "sub main::setLHNRE"
package main; sub setLHNRE {
    my @h = split(/\|/o,$_[0]);
    my @s;
    push(@s,'localhost'); # 'localhost' alias
    push(@s,join('|',@h)) if @h;
    my $s=join('|',@s);
    SetRE('LHNRE',"^(?:$s)\$|$IPloopback",
          $regexMod,
          'Local Host Names',$_[1]);
}
