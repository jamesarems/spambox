#line 1 "sub main::thisIsSpam"
package main; sub thisIsSpam {
    my ($fh,$reason,$log,$error,$testmode,$slok,$done)=@_;
    return 0 unless $fh;
    my $this=$Con{$fh};
    d("thisIsSpam - $reason , $testmode, $slok, $done");
    return 0 if ($this->{detectonly} && $this->{error});   # we are in ERROR mode
                                                           # we do not have to do
                                                           # anything for Plugins
    &makeSubject($fh);
    my $logsub;
    $this->{messagereason}=$reason;
    my ($to) = $this->{rcpt} =~ /(\S+)/o;
    $to = lc($to);
    my ($mfd,$mfu); ($mfu,$mfd) = ($1,$2) if $to =~ /($EmailAdrRe)\@($EmailDomainRe)/o;
    $error = $SpamError if !$error;
    $error =~ s/LOCALUSER/$mfu/go;
    $error =~ s/LOCALDOMAIN/$mfd/go;

    if ( $reason =~ /bayes/io ) {
        if (allSH( $this->{rcpt}, 'baysTestModeUserAddresses' )) {
            $testmode = "bayesian test mode user";
            $slok=0; # make sure it's not flagged as a spam lover
        }
    }

    addSpamProb( $fh, 0, 1 );
    $this->{spamfound} = 1;   # Set spamfound flag.

    $testmode = "testmode" if $testmode eq '1';
    $testmode  = "all in testmode" if $allTestMode;
    $testmode = $slok = 0 if allSH( $this->{rcpt}, 'spamHaters' );
    if ($slok && defined $this->{spamMaxScore} && $this->{messagescore} > $this->{spamMaxScore}) {
        $slok = 0;
        mlog($fh, "The message score ($this->{messagescore}) exceeds the SpamLover-Max-Score ($this->{spamMaxScore}) - SpamLover is ignored");
    }
    
    makeMyheader($fh,$slok,$testmode,$reason);

    return 1 if ($this->{error});  # we are already in error-mode - writing our headers is enough
    
    my $passtext;

    if(    $slok
        || $testmode
        || $this->{tagmode}
        || (($this->{spamlover} & 1) && defined $this->{spamMaxScore} && $this->{messagescore} <= $this->{spamMaxScore})
        || (! $this->{detectonly} && ($this->{messagelow} || ($this->{bayeslowconf} && $reason =~ /bayes|hmm/io)))
      )
    {
        if($slok) {
            $this->{prepend}.="[sl]";
            $this->{saveprepend2}.="[sl]";
            $passtext="passing because spamlover for this check, otherwise blocked ($reason)";
            $Stats{spamlover}++;
            $log = 6 if $log == 7;   # do not forward spam, the mail will be delivered
            $log = 1 if $log == 3;   # do not forward spam, the mail will be delivered
            $done = 1;
        }elsif ( $testmode ) {
            $this->{prepend}.="[testmode]";
            $this->{saveprepend2}.="[testmode]";
            $passtext = "passing because $testmode, otherwise blocked ($reason)";
            $done = 1;
        }elsif($this->{tagmode}) {
            $this->{prepend}.="[tagmode]";
            $passtext="passing because tagmode: $this->{rcpt}, otherwise blocked ($reason)";
            $done = 1;
        }elsif($this->{spamlover} & 1) {
            $this->{prepend}.="[all-sl]";
            $this->{saveprepend2}.="[all-sl]";
            $passtext="passing because ";
            $passtext .= ($this->{spamlover} == 1) ? 'all spamlover [address match in \'spamLovers\']' : 'content matches in \'SpamLoversRe\'';
            $passtext .= ", otherwise blocked ($reason)";
            $Stats{spamlover}++;
            $log = 6 if $log == 7;   # do not forward spam, the mail will be delivered
            $log = 1 if $log == 3;   # do not forward spam, the mail will be delivered
            $done = 1;
        }elsif ($this->{messagelow})  {
            $this->{prepend}.="[lowlimit]";
            $this->{saveprepend2}.="[lowlimit]";
            $passtext="passing because messagescore($this->{messagescore}) low";
            $done = 1;
        }elsif($this->{bayeslowconf}) {
            $this->{prepend}.="[lowconfidence]";
            $this->{saveprepend2}.="[lowconfidence]";
            $passtext="passing because of low confidence, otherwise blocked ($reason)";
        }

        # pretend it's not spam
        $this->{header}=~s/^($HeaderRe*)/$1From: sender not supplied\r\n/o unless $this->{header}=~/^$HeaderRe*From:/io; # add From: if missing
        $this->{header}=~s/^($HeaderRe*)/$1Subject:\r\n/o unless $this->{header}=~/^$HeaderRe*Subject:/io; # add Subject: if missing
        unless ($slok && $spamTagSL ) {
            $this->{header} =~ s/^Subject:/Subject: $this->{prepend}/imo
              if ( $spamTag && $this->{prepend} ne '' && $this->{header} !~ /Subject: \Q$this->{prepend}\E/i);
        }

        unless ( $slok && $spamSubjectSL ) {
            $this->{header} =~ s/^Subject:/Subject: $spamSubjectEnc/imo
              if $spamSubjectEnc && $this->{header} !~ /Subject: \Q$spamSubjectEnc\E/i;
        }

        #Lets check if its safe to pass if not already done so.

        if ($done) {
            if (! $this->{maillogfh}) {
                my $fn = Maillog($fh,'',$log); # tell maillog what this is.
                $fn=' -> '.$fn if $fn ne '';
                $fn='' if !$fileLogging;
                $logsub =
                  ( $subjectLogging ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );

                mlog($fh,"[spam found] and possibly $passtext$logsub".de8($fn),0,2);
            }
            delayWhiteExpire($fh);
            if ($this->{detectonly}) {
                return 0;
            } else {
                isnotspam($fh,$done) unless $this->{skipnotspam};
            }
        } else {
            $this->{getline}=\&getbody unless $this->{getline} eq \&getheader;
        }
        return 0;
    } else {
        $this->{logalldone} = &MaillogRemove($this) if ($this->{maillogfilename});
        my $fn = $this->{maillogfilename};
        $fn = Maillog($fh,'',$log) unless ($fn); # tell maillog what this is.
        delete $this->{logalldone};
        $fn=' -> '.$fn if $fn ne '';
        $fn='' if !$fileLogging;
        $logsub = ( $subjectLogging && $this->{originalsubject} ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
        $this->{prepend} .= '[isbounce]' if $this->{isbounce} && $this->{prepend} !~ /\[isbounce\]/o  ;
        mlog($fh,"[spam found] (". $reason . ")$logsub".de8($fn).';',0,2);
        delayWhiteExpire($fh);
        $error=$SpamError if $error eq '';
        $error=~s/500/554/io;

        seterror($fh,$error,$done) unless $this->{fakeAUTHsuccess};
        return 1;
    }
}
