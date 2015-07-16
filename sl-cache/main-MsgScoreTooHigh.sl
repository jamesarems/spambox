#line 1 "sub main::MsgScoreTooHigh"
package main; sub MsgScoreTooHigh {
    my ($fh,$done) = @_;
    d('MsgScoreTooHigh');
    if (&TestMessageScore($fh)) {
        MessageScore($fh,$done);
        return 1 if ($Con{$fh}->{error});
    }
    return 0;
}
