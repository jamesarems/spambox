#line 1 "sub main::makeMyheader"
package main; sub makeMyheader {
    my ($fh,$slok,$testmode,$reason) = @_;
    my $this = $Con{$fh};
    d('makeMyheader');
    # add to our header; merge later, when client sent own headers
    my $header = $this->{myheader};
    $this->{myheader} = '';
    $this->{myheader}.="X-Assp-Version: $version$modversion on $myName\r\n"
        if $header !~ /X-Assp-Version:.+? on \Q$myName\E/;
    $this->{myheader}.= "X-Assp-ID: $myName $this->{msgtime}\r\n"
        if $header !~ /X-Assp-ID: \Q$myName $this->{msgtime}\E/;
    my $sID = $this->{SessionID};
    my $nbr = $this->{chainMailInSession} + (($this->{chainMailInSession} < 0)?2:1);
    $sID .= " (mail $nbr)";
    $this->{myheader}.= "X-Assp-Session: $sID\r\n"
        if $header !~ /X-Assp-Session:/o;
    if (! $this->{relayok}) {
        $this->{myheader}.= "X-Assp-OIP: $this->{cip}\r\n"
            if $this->{cip} && $this->{ispip} && $header !~ /X-Assp-OIP: \Q$this->{cip}\E/;
        $this->{myheader}.= "X-Assp-Detected-RIP: ".join(', ',@{$this->{sip}})."\r\n"
            if @{$this->{sip}} && $header !~ /X-Assp-Detected-RIP:/o;
        $this->{myheader}.= "X-Assp-Source-IP: $this->{ssip}\r\n"
            if $this->{ssip} && $header !~ /X-Assp-Source-IP: \Q$this->{ssip}\E/;
    }
    $this->{myheader}.= "X-Assp-Envelope-From: $this->{mailfrom}\r\n"
        if $AddIntendedForHeader && $this->{mailfrom} && $header !~ /X-Assp-Envelope-From: \Q$this->{mailfrom}\E/;
    for (split(/ /o,$this->{rcpt})) {
        $this->{myheader}.= "X-Assp-Intended-For: $_\r\n"
            if $AddIntendedForHeader && $_ && $header !~ /X-Assp-Intended-For: \Q$_\E/i;
    }
    $this->{myheader}.="X-Assp-Original-Subject: $this->{subject2}\r\n"
        if $AddSubjectHeader && $this->{subject2} && $header !~ /X-Assp-Original-Subject:/;
    $this->{myheader}.=$header;

    my $red = $this->{red};
    $red =~ s/\r|\n//gos;
    $red =~ s/\s+/ /gos;
    my $red2 = substr($red,0,$RegExLength);
    $red2 .= '...' if $red ne $red2;
    $red2 = $red if $red =~ /^$EmailAdrRe\@$EmailDomainRe$/o;
    $this->{myheader}.="X-Assp-Redlisted: Yes ($red2)\r\n"
        if $this->{red} && $this->{myheader} !~ /X-Assp-Redlisted/o;
    if ($this->{spamfound} && $AddSpamHeader) {
        foreach my $k (sort keys(%{$this})) {
            next if $k !~ /love/oi;
            next if $this->{$k} == 2;
            next unless $this->{$k};
            next if ref($this->{$k});
            $this->{myheader}.= "X-Assp-$k: $this->{$k}\r\n" if $this->{myheader} !~ /X-Assp-$k/;
        }
    }
    $this->{myheader}.= "X-Assp-Spam: YES\r\n"
        if $this->{spamfound} && $AddSpamHeader && !($this->{bayeslowconf} || $this->{messagelow}) && $this->{myheader} !~ /X-Assp-Spam: YES/o;
    $this->{myheader}.= "X-Assp-Spam: YES (Probably)\r\n"
        if $this->{spamfound} && $AddSpamHeader && ($this->{bayeslowconf} || $this->{messagelow}) && $this->{myheader} !~ /X-Assp-Spam: YES \(Probably\)/o;
    $this->{myheader}.="X-Assp-Block: NO (Spamlover)\r\n"
        if $this->{spamfound} && $slok && $this->{myheader} !~ /X-Assp-Block: NO \(Spamlover\)/o;
    $this->{myheader}.="X-Assp-Block: NO ($testmode)\r\n"
        if $this->{spamfound} && $testmode && !$this->{messagelow} && $this->{myheader} !~ /X-Assp-Block: NO \(\Q$testmode\E\)/;
    $this->{myheader}.="$AddCustomHeader\r\n"
        if $this->{spamfound} && $AddCustomHeader && $this->{myheader} !~ /\Q$AddCustomHeader\E/;
    $this->{myheader}.="X-Assp-Spam-Reason: ".$reason."\r\n"
        if $this->{spamfound} && $reason && $AddSpamReasonHeader &&
           $this->{myheader} !~ /X-Assp-Spam-Reason: \Q$reason\E/;

    if ($this->{spamfound} && $AddScoringHeader) {
        $this->{myheader} =~ s/X-Assp-Message-Totalscore:$HeaderValueRe//iogs;
        $this->{myheader} .= "X-Assp-Message-Totalscore: $this->{messagescore}\r\n";
    }
    if (   (! $this->{relayok} || ($this->{relayok} && ! $NoExternalSpamProb ) )
        && $this->{messagescore} > 0
        && $AddLevelHeader
#        && $this->{spamfound}
       )
    {
        my $mscore = $this->{messagescore};
        $mscore = 99 if $mscore > 99;
        $mscore = int($mscore/5) + 1;
        my $stars = '*' x $mscore;
        $this->{myheader} =~ s/X-Assp-Spam-Level:$HeaderValueRe//gios; # clear out existing X-Assp-Spam-Level headers
        $this->{myheader} .= "X-Assp-Spam-Level: $stars\r\n";
    }
}
