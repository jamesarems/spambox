#line 1 "sub main::FShelo"
package main; sub FShelo { my ($fh,$l)=@_;
    if($l=~/^ *[54]/o) {
        FSabort($fh,"helo Expected 220, got: $l");
    } elsif($l=~/^ *220 /o) {
        sendque($fh,"HELO $myName\r\n");
        $Con{$fh}->{getline}=\&FSfrom;
    }
}
