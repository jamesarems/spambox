#line 1 "sub main::CCquit"
package main; sub CCquit { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        CCabort($fh,"[CR][LF].[CR][LF] sent, Expected 250, got: $l");
    } else {
        sendque($fh,"QUIT\r\n");
        $Con{$fh}->{CClastCMD} = 'QUIT';
        $Con{$fh}->{getline}=\&CCdone;
        $Con{$fh}->{type} = 'CC';          # start timeout watching for case 221/421 will not be send
        $Con{$fh}->{timelast} = time;
        $Con{$fh}->{nodelay} = 1;
    }
}
