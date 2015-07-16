#line 1 "sub main::skipok"
package main; sub skipok {
    d('skipok');
    my ($fh,$l)=@_;
    if($l=~/^250/o) {
        $Con{$fh}->{getline}=\&reply;
    } else {
        reply($fh,$l);
    }
}
