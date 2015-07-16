#line 1 "sub main::CCdone"
package main; sub CCdone { my ($fh,$l)=@_;
    if($l!~/^ *[24]21/o) {
        CCabort($fh,"QUIT sent, Expected 221 or 421, got: $l");
    } else {
        done2($fh); # close and delete
    }
}
