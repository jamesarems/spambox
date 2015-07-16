#line 1 "sub main::RMrcpt"
package main; sub RMrcpt { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        RMabort($fh,"rcpt Expected 250, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    } else {
        sendque($fh,"RCPT TO: <$Con{$fh}->{to}>\r\n");
        $Con{$fh}->{getline}=\&RMdata;
    }
}
