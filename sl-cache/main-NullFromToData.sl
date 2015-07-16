#line 1 "sub main::NullFromToData"
package main; sub NullFromToData { my ($fh,$l)=@_;
    d('NullFromToData');
    ($Con{$fh}->{lastcmd}) = $l =~ /^([^\s]+)/o;
    push(@{$Con{$fh}->{cmdlist}},$Con{$fh}->{lastcmd}) if $ConnectionLog >= 2;
    if($l=~/^DATA/io) {
        if (! $Con{$fh}->{rcpt}) {
            sendque($fh,"503 must have recipient first\r\n");
            return;
        }
        $Con{$fh}->{getline}=\&NullData;
        sendque($fh,"354 send data\r\n");
    } elsif ($l=~/^HELO|EHLO/io){
        sendque($fh,"220 OK - $myName ready\r\n");
    } elsif ($l=~/^RSET/io){
        my $s = $Con{$fh}->{messagescore};
        &stateReset($fh);
        $Con{$fh}->{messagescore} = $s if ($Con{$fh}->{fakeAUTHsuccess} > 1);
        sendque($Con{$fh}->{friend},"RSET\r\n");
        $Con{$fh}->{getline}=\&getline unless $Con{$fh}->{fakeAUTHsuccess};
    } elsif ($l=~/^MAIL FROM:/io){
        if ($Con{$fh}->{fakeAUTHsuccess}) {
            my $s = $Con{$fh}->{messagescore};
            &stateReset($fh);
            $Con{$fh}->{messagescore} = $s if ($Con{$fh}->{fakeAUTHsuccess} > 1);
            ($Con{$fh}->{mailfrom}) = $l =~ /($EmailAdrRe\@$EmailDomainRe)/io;
            sendque($fh,"250 OK $Con{$fh}->{mailfrom}\r\n");
        } else {
            $Con{$fh}->{getline}=\&getline;
            &getline($fh,$l);
        }
    } elsif ($l=~/^QUIT/io){
        sendque($fh,"221 <$myName> closing transmission\r\n");
        $Con{$fh}->{closeafterwrite} = 1;
        done2($Con{$fh}->{friend}); # close and delete
    } elsif ($l=~/^RCPT TO:/io) {
        if (! $Con{$fh}->{mailfrom}) {
            sendque($fh,"503 must have sender first\r\n");
            return;
        }
        my ($s) = $l =~ /($EmailAdrRe\@$EmailDomainRe)/io;
        if ($s =~ /\.$TLDSRE$/i) {
            $Con{$fh}->{rcpt} .= "$s ";
            sendque($fh,"250 OK $s\r\n");
        } else {
            sendque($fh,"550 $s no valid domain\r\n");
        }
    } elsif ($l=~/^(?:NOOP|HELP)/io) {
        sendque($fh,"250 OK\r\n");
    } else {
        sendque($fh,"502 command not implemented\r\n");
    }
}
