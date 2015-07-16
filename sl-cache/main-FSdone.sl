#line 1 "sub main::FSdone"
package main; sub FSdone { my ($fh,$l)=@_;
    if($l!~/^ *[24]21/o) {
        FSabort($fh,"QUIT sent, Expected 221 or 421, got: $l");
    } else {
        @{$Con{$fh}->{to}} = (); undef @{$Con{$fh}->{to}};
        done2($fh); # close and delete
    }
}
