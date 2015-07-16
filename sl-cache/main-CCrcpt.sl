#line 1 "sub main::CCrcpt"
package main; sub CCrcpt { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        CCabort($fh,"MAIL FROM sent, Expected 250, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    } else {
        sendque($fh,"RCPT TO: <$Con{$fh}->{to}>\r\n");
        $Con{$fh}->{CClastCMD} = 'RCPT TO';
        $Con{$fh}->{getline}=\&CCdata;
    }
}
