#line 1 "sub main::Delayok"
package main; sub Delayok {
    my($fh,$rcpt)=@_;
    return 1 if !$EnableDelaying;
    return Delayok_Run($fh,$rcpt);
}
