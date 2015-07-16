#line 1 "sub main::FSrcpt"
package main; sub FSrcpt { my ($fh,$l)=@_;
    if($l=~/^ *[54]/o) {
        FSabort($fh,"send $Con{$fh}->{FSlastCMD}, expected 250, got: $l");
    } elsif($l=~/^ *250 /o) {
        $Con{$fh}->{FSlastCMD} = "RCPT TO: <" . shift(@{$Con{$fh}->{to}}) . ">";
        sendque($fh,"$Con{$fh}->{FSlastCMD}\r\n");
        $Con{$fh}->{getline} = \&FSnoop unless @{$Con{$fh}->{to}};
    }
}
