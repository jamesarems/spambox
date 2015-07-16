#line 1 "sub main::RMquit"
package main; sub RMquit { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        RMabort($fh,"quit Expected 250, got: $l");
    } else {
        sendque($fh,"QUIT\r\n");
        $Con{$fh}->{getline}=\&RMdone;
        $Con{$fh}->{type} = 'C';          # start timeout watching for case 221/421 will not be send
        $Con{$fh}->{timelast} = time;
        $Con{$fh}->{nodelay} = 1;
    }
}
