#line 1 "sub main::FSquit"
package main; sub FSquit { my ($fh,$l)=@_;
    if($l!~/^ *250/o) {
        FSabort($fh,"[CR][LF].[CR][LF] sent, Expected 250, got: $l");
    } else {
        sendque($fh,"QUIT\r\n");
        $Con{$fh}->{FSlastCMD} = 'QUIT';
        $Con{$fh}->{getline}=\&FSdone;
        $Con{$fh}->{type} = 'CC';          # start timeout watching for case 221/421 will not be send
        $Con{$fh}->{timelast} = time;
        $Con{$fh}->{nodelay} = 1;
    }
}
