#line 1 "sub main::CChelo"
package main; sub CChelo { my ($fh,$l)=@_;
    if($l=~/^ *220 /o) {
        sendque($fh,"HELO $myName\r\n");
        $Con{$fh}->{CClastCMD} = 'HELO';
        $Con{$fh}->{getline}=\&CCfrom;
    } elsif ($l=~/^ *220-/o){
    } else {
        CCabort($fh,"helo Expected 220, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    }
}
