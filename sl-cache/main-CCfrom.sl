#line 1 "sub main::CCfrom"
package main; sub CCfrom { my ($fh,$l)=@_;
    if($l=~/^ *250 /o) {
        sendque($fh,"MAIL FROM: ".($Con{$fh}->{from}=~/(<[^<>]+>)/o ?$1:"<$Con{$fh}->{from}>")."\r\n");
        $Con{$fh}->{CClastCMD} = 'MAIL FROM';
        $Con{$fh}->{getline}=\&CCrcpt;
    } elsif ($l=~/^ *250-/o) {
    } else {
        CCabort($fh,"HELO sent, Expected 250, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    }
}
