#line 1 "sub main::FSdata"
package main; sub FSdata { my ($fh,$l)=@_;
    delete $Con{$fh}->{sendTime};
    if($l=~/^ *[54]/o) {
        FSabort($fh,"send $Con{$fh}->{FSlastCMD}, expected 250, got: $l");
    } elsif($l=~/^ *250 /o) {
        sendque($fh,"DATA\r\n");
        $Con{$fh}->{getline}=\&FSdata2;
    }
}
