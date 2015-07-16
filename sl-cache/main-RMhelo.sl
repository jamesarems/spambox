#line 1 "sub main::RMhelo"
package main; sub RMhelo { my ($fh,$l)=@_;
    if($l=~/^ *220 /o) {
        sendque($fh,"HELO $myName\r\n");
        $Con{$fh}->{getline}=\&RMfrom;
    } elsif ($l=~/^ *220-/o) {
    } else {
        RMabort($fh,"helo Expected 220, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    }
}
