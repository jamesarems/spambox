#line 1 "sub main::CCdata"
package main; sub CCdata { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        CCabort($fh,"RCPT TO sent, Expected 250, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    } else {
        sendque($fh,"DATA\r\n");
        $Con{$fh}->{CClastCMD} = 'DATA';
        $Con{$fh}->{getline}=\&CCdata2;
    }
}
