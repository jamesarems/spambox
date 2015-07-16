#line 1 "sub main::addSpamProb"
package main; sub addSpamProb {
    my ($fh,$wl,$sp)=@_;
    my $this=$Con{$fh};
    my $spamprobheader='';
    my $mscore;
    d('addSpamProb');
    return if $NoExternalSpamProb && $this->{relayok};
    $spamprobheader = sprintf( "X-Assp-Spam-Prob: %.5f\r\n", $this->{spamprob} )
      if $this->{spamprob} > 0.00001 && $AddSpamProbHeader;
    $spamprobheader .= sprintf( "X-Assp-Bayes-Confidence: %.5f\r\n", $this->{spamconf} )
      if $AddSpamProbHeader
          && $AddConfidenceHeader
          && $baysConf
          && $this->{spamconf} > 0.00001;
    $spamprobheader .= sprintf( "X-Assp-HMM-Spam-Prob: %.5f\r\n", $this->{hmmprob} )
      if $this->{hmmprob} > 0.00001 && $AddSpamProbHeader;
    $spamprobheader .= sprintf( "X-Assp-HMM-Confidence: %.5f\r\n", $this->{hmmconf} )
      if $AddSpamProbHeader
          && $AddConfidenceHeader
          && $baysConf
          && $this->{hmmconf} > 0.00001;

    $this->{myheader}=~s/X-Assp-Spam-Prob:$HeaderValueRe//gios; # clear out existing X-Assp-Spam-Prob headers
    $this->{myheader}=~s/X-Assp-Bayes-Confidence:$HeaderValueRe//gios; # clear out existing X-Assp-Bayes-Confidence headers
    $this->{myheader}=~s/X-Assp-HMM-Spam-Prob:$HeaderValueRe//gios; # clear out existing X-Assp-HMM-Spam-Prob headers
    $this->{myheader}=~s/X-Assp-HMM-Confidence:$HeaderValueRe//gios; # clear out existing X-Assp-HMM-Confidence headers
    if ($wl || $this->{whitelisted}) {
        my $reason = $this->{passingreason} =~ /white|authenticated/oi ? $this->{passingreason} : '';
        $reason = 'whiteRe' if $reason =~ /whitere/io;
        $reason =~ s/\r?\n/ /go;
        $reason = ' ('.$reason.')' if $reason;
        $spamprobheader.="X-Assp-Whitelisted: Yes$reason\r\n";
        $this->{myheader}=~s/X-Assp-Whitelisted:$HeaderValueRe//gios; # clear out existing X-Assp-Whitelisted headers
    }
    my $strippedTag=$this->{prepend};
    $this->{saveprepend}=$this->{prepend};
    $strippedTag=~s/\[//o;
    $strippedTag=~s/\]//o;
    if ($sp && $this->{prepend} && $tagLogging) {
        $this->{myheader}=~s/X-Assp-Tag:$HeaderValueRe//gios; # clear out existing X-Assp-Tag headers
        $spamprobheader.="X-Assp-Tag: $strippedTag\r\n";
    }

    # add to our header; merge later, when client sent own headers
    $this->{myheader}.=$spamprobheader;
}
