#line 1 "sub main::MsgIDOK_Run"
package main; sub MsgIDOK_Run {
    my $fh = shift;
    d('MsgIDOK');
    my $this = $Con{$fh};
    my $tlit;
    my $notvalid = 0;
    return 1 if $this->{msgiddone};
    $this->{msgiddone} = 1;
    $this->{prepend} = '';

    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    mlog($fh,"Message-ID found: $this->{msgid}") if $this->{msgid} && $ValidateSenderLog >= 2;
    skipCheck($this,'co','ib','rw','nd','sb','ro','wl','np','ispcip') && return 1;
    return 1 if $this->{ip}=~/$IPprivate/o;
    return 1 if matchIP( $ip, 'noMsgID', $fh ,0);

    $tlit = &tlit($DoMsgID);
    my ($userpart) = $this->{mailfrom} =~ /([^@]*)@/o;
    my ($domainpart) = $this->{msgid} =~ /@([^@]*)/o;

    if (! $this->{msgid} ) {
        $this->{prepend} = "[MsgID]";
        $this->{messagereason} = "Message-ID missing";
        mlog( $fh, "$tlit ($this->{messagereason})" ) if $ValidateSenderLog;
        return 1 if $DoMsgID == 2;
        pbAdd( $fh, $ip, 'midmValencePB', 'Msg-IDmissing' );
        return 1 if $DoMsgID == 3;
        $Stats{msgMSGIDtrErrors}++;
        return 0;
    };

    my %MSGIDs = &BombWeight($fh,$this->{msgid},'invalidMsgIDRe' );
    if (    $invalidMsgIDRe
        && $MSGIDs{count} )
    {

        $this->{prepend} = "[MsgID]";
        $this->{messagereason} = "Message-ID invalid: '$this->{msgid}'";
        my $tlit = ($DoMsgID == 1 && $MSGIDs{sum} < ${'midiValencePB'}[0]) ? &tlit(3) : $tlit;
        mlog( $fh, "$tlit ($this->{messagereason})" ) if $ValidateSenderLog;
        return 1 if $DoMsgID == 2;
        pbAdd( $fh, $ip, calcValence($MSGIDs{sum},'midiValencePB') , 'Msg-IDinvalid' );
        return 1 if $DoMsgID == 3 || $MSGIDs{sum} < ${'midiValencePB'}[0];
        $notvalid = 1;
        
    } elsif (    $validMsgIDRe
        && $this->{msgid} !~ /$validMsgIDReRE/i )
    {
        $this->{prepend} = "[MsgID]";
        $this->{messagereason} = "Message-ID not valid: '$this->{msgid}'";
        mlog( $fh, "$tlit ($this->{messagereason})" ) if $ValidateSenderLog;
        return 1 if $DoMsgID == 2;
        pbAdd( $fh, $ip, 'midiValencePB', 'Msg-IDnotvalid' );
        return 1 if $DoMsgID == 3;
        $notvalid = 1;
    }

    if (! $notvalid && $this->{msgid} =~ /\Q$userpart\E/i && $domainpart !~ /$EmailDomainRe/io) {
        $this->{prepend} = "[MsgID]";
        $this->{messagereason} = "Message-ID suspicious: '$this->{msgid}'";
        mlog( $fh, "$tlit ($this->{messagereason})" ) if $ValidateSenderLog;
        return 1 if $DoMsgID == 2;
        pbAdd( $fh, $ip, 'midsValencePB', 'Msg-IDsuspicious' ) if $DoMsgID == 3;
        return 1 if $DoMsgID == 3;
        $notvalid = 1;
    }

    if ($notvalid) {
        $Stats{msgMSGIDtrErrors}++;
        return 0;
    }
    return 1;
}
