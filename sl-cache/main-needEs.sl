#line 1 "sub main::needEs"
package main; sub needEs {
    my ($count,$text,$es)=@_;
    return $count . $text . ($count==1 ? '' : $es);
}
