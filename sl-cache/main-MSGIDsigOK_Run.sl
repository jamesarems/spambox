#line 1 "sub main::MSGIDsigOK_Run"
package main; sub MSGIDsigOK_Run {
    my $fh = shift;
    d('MSGIDsigOK');
    my $this = $Con{$fh};

    return 1 if $this->{msgidsigdone};
    $this->{msgidsigdone} = 1;

    return if ! $this->{isbounce};
    skipCheck($this,'co','sb','ro') && return 1;
    return 1 if ($this->{whitelisted} && !$BackWL) ;
    return 1 if (($this->{noprocessing} & 1) && !$BackNP);
    return 1 if &matchIP($this->{ip},'noBackSctrIP',$fh,0);
    return 1 if ($MSGIDsigAddresses && ! matchSL($this->{rcpt},'MSGIDsigAddresses'));
    return 1 if ( matchSL([$this->{rcpt},$this->{mailfrom}],'noBackSctrAddresses'));
    if ($noBackSctrRe && $this->{header} =~ /(noBackSctrReRE)/) {
       mlogRe($fh,($1||$2),'noBackSctrRe','nobackscatter');
       return 1;
    }

    my $tlit = &tlit($DoMSGIDsig);

    if (&MSGIDsigCheck($fh)) {
        $this->{prepend}="[MSGID-sig]";
        mlog($fh,"$tlit MSGID signing OK for bounce message") if $MSGIDsigLog >= 2;
        return 1;
    }

    $this->{prepend}="[MSGID-sig]";
    $this->{messagereason}="MSGID-sig check failed for bounce sender $this->{mailfrom}";
    mlog($fh,"$tlit $this->{messagereason}") if $MSGIDsigLog;
    return 1 if ($DoMSGIDsig == 2 || $DoMSGIDsig == 4);
    delete $this->{messagescoredone};
    pbWhiteDelete($fh,$this->{ip});
    pbAdd($fh,$this->{ip},'fbmtvValencePB','MSGID-signature-failed');
    $Stats{msgMSGIDtrErrors}++;

    if ($DoMSGIDsig == 3) {
        if (&TestMessageScore($fh)) {
            delete $this->{messagelow};
            MessageScore($fh,1);
        }
        return 0 if (&MsgScoreTooHigh($fh,1));
        return 1;
    }

    if ($Back250OKISP && ($this->{ispip} || $this->{cip})) {
        $this->{accBackISPIP} = 1;
        mlog($fh,"info: force sending 250 OK to ISP for failed bounced message",1) if $BacksctrLog;
        return 1;
    } else {
#        $this->{messagelow} = &TestLowMessageScore($fh);
        thisIsSpam($fh,$this->{messagereason},$BackLog,'554 5.7.8 Bounce address - message was never sent by this domain',0,0,1);
        return 0;
    }
}
