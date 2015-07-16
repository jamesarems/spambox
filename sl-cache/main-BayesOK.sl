#line 1 "sub main::BayesOK"
package main; sub BayesOK {
    my($fh,$msg,$ip)=@_;
    d('BayesOK');
    if ($lockBayes) {
        mlog($fh,"Bayesian is not available - hmmdb is still locked by a rebuild task") if $BayesianLog;
        delete $Con{$fh}->{skipBayes};
        return 1;
    }
    my $this=$Con{$fh};
    my $DoBayesian = $DoBayesian;    # copy the global to local - using local from this point
    $DoBayesian = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
    if ($this->{bayesdone}) {
        delete $this->{skipBayes};
        return 1;
    }
    $this->{bayesdone} = 1;
    if (!$DoBayesian) {
        delete $this->{skipBayes};
        return 1;
    }
    my $res = BayesOK_Run($fh,$msg,$ip);
    @HmmBayWords = ();
    return $res;
}
