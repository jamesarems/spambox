#line 1 "sub main::MaxErrorsFailed"
package main; sub MaxErrorsFailed {
    my ($fh, $sendreason, $logreason, $toclose) = @_;
    delayWhiteExpire($fh);
    NoLoopSyswrite( $fh, $sendreason ,0);
    $Con{$fh}->{prepend}="[MaxErrors]";
    $Con{$fh}->{messagereason}="max errors ($MaxErrors) exceeded";
    mlog($fh,$logreason);
    pbAdd($fh,$Con{$fh}->{ip},'meValencePB',"MaxErrors",($Con{$fh}->{noprocessing} & 1));
    $Stats{msgMaxErrors}++;
    $toclose ||= $fh;
    done($toclose);
}
