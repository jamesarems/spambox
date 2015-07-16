#line 1 "sub main::RMfrom"
package main; sub RMfrom { my ($fh,$l)=@_;
    if($l=~/^ *250 /o) {
        sendque($fh,"MAIL FROM: ".($Con{$fh}->{from}=~/(<[^<>]+>)/o ? $1 : $Con{$fh}->{from})."\r\n");
        $Con{$fh}->{getline}=\&RMrcpt;
    } elsif ($l=~/^ *250-/o) {
    } else {
        RMabort($fh,"from Expected 250, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    }
}
