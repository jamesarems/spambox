#line 1 "sub main::RMdata"
package main; sub RMdata { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        RMabort($fh,"data Expected 250, got: $l (from:$Con{$fh}->{from} to:$Con{$fh}->{to})");
    } else {
        sendque($fh,"DATA\r\n");
        $Con{$fh}->{getline}=\&RMdata2;
    }
}
