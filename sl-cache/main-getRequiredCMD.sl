#line 1 "sub main::getRequiredCMD"
package main; sub getRequiredCMD {
    my($fh,$l)=@_;
    d("getRequiredCMD - $l");
    my $this=$Con{$fh};
    if (! $this->{requiredCMD}) {          # no need to do anything - just process
        $this->{getline} = \&getline;
        delete $this->{requiredCMD};
        return getline($fh,$l);
    }
    if ($l =~ /^\s*(?:$this->{requiredCMD})/i) {    # the required command is used
        $this->{getline} = \&getline;
        delete $this->{requiredCMD};
        return getline($fh,$l);
    } elsif ($l =~ /^\s*help/io) {                # HELP was sent - tell the peer the required commands
        $this->{lastcmd} = 'HELP';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        my $cmd = $this->{requiredCMD};
        $cmd =~ s/\|/ /o;
        $cmd =~ s/mail from:/mail/oi;
        $cmd = uc($cmd);
        sendque($fh, "211 $cmd\r\n");
    } elsif ($l =~ /^\s*noop/io) {
        $this->{lastcmd} = 'NOOP';               # NOOP was sent - just send OK
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        sendque($fh, "250 OK\r\n");
    } else {                                     # a wrong command is used by the peer - close the connection
        $l =~ s/\r|\n//go;
        my $cmd = uc($this->{requiredCMD});
        $cmd =~ s/\|/,/o;
        $cmd .= ',NOOP,HELP';
        mlog($fh,"info: required and expected SMTP commands are: '$cmd' - got '$l' from the peer - dropping connection") if $ConnectionLog;
        ($this->{lastcmd}) = $l =~ /^\s*(\S+)/;
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2 && $this->{lastcmd};
        $this->{getline} = \&getline;
        if($MaxErrors && ++$this->{serverErrors} > $MaxErrors) {
            $this->{outgoing} = '';
            MaxErrorsFailed($fh,
            "503 Bad sequence of commands\r\n421 <$myName> closing transmission\r\n",
            "max errors (MaxErrors=$MaxErrors) exceeded -- dropping connection",0);
            return;
        }
        delayWhiteExpire($fh);
        NoLoopSyswrite( $fh, "503 Bad sequence of commands\r\n421 <$myName> closing transmission\r\n" ,0);
        done($fh);
        $Stats{msgMaxErrors}++ if $MaxErrors;
    }
}
