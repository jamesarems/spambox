#line 1 "sub main::HMMOK"
package main; sub HMMOK {
    my($fh,$msg)=@_;
    d('HMMOK');
    if ($lockHMM) {
        mlog($fh,"HMM is not available - hmmdb is still locked by a rebuild task") if $BayesianLog;
        return 1;
    }
    my $this = $Con{$fh};
    my $DoHMM = $DoHMM;
    $DoHMM = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
    return 1 if $this->{HMMdone};
    $this->{HMMdone} = 1;
    return 1 if !$DoHMM;
    return HMMOK_Run($fh,$msg);
}
