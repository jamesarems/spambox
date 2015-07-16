#line 1 "sub main::FSnoop"
package main; sub FSnoop { my ($fh,$l)=@_;
    if ($Con{$fh}->{gotAllText}) {
        &FSdata($fh,$l);
        return;
    }
    if($l=~/^ *[54]/o) {
        FSabort($fh,"send $Con{$fh}->{FSlastCMD}, expected 250, got: $l");
    } elsif($l=~/^ *250 /o) {
        sendque($fh,"NOOP\r\n");
        $Con{$fh}->{FSnoopCount}++ if $Con{$fh}->{FSnoopCount} < 5;
        $Con{$fh}->{sendTime} = time + $Con{$fh}->{FSnoopCount};
        $Con{$fh}->{FSlastCMD} = 'NOOP';
    }
}
