#line 1 "sub main::FSfrom"
package main; sub FSfrom { my ($fh,$l)=@_;
    if($l=~/^ *[54]/o) {
        FSabort($fh,"send HELO($myName), expected 250, got: $l");
    } elsif($l=~/^ *250 /o) {
        $Con{$fh}->{FSlastCMD} = "MAIL FROM: <$Con{$fh}->{from}>";
        sendque($fh,"$Con{$fh}->{FSlastCMD}\r\n");
        $Con{$fh}->{getline}=\&FSrcpt;
    }
}
