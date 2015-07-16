#line 1 "sub main::replyEHLO"
package main; sub replyEHLO {
    d('replyEHLO');
    my ($fh,$l)=@_;
    my $this=$Con{$fh};
    my $cli=$this->{friend};
#    $this->{lastEHLOreply} = $l;
    d("lastReply3 = $l");

    $Con{$cli}->{inerror} = ($l=~/^5[05][0-9]/o);
    $Con{$cli}->{intemperror} = ($l=~/^4\d{2}/o);
    if ($l=~/^(?:1|2|3)\d{2}/o) {
        delete $Con{$cli}->{inerror};
        delete $Con{$cli}->{intemperror};
    }

    &reply($fh,$l) if ($l=~/^250[ \-]+STARTTLS/io ||
                       $l=~/^5/o ||
                       $l=~/^4/o ||
                       $l=~/^221/o);
    if (! $Con{$cli}->{relayok} && $l =~ /^250[ \-]+(XCLIENT|XFORWARD) +(.+)\s*\r\n$/io) {
        $Con{$cli}->{uc $1} = uc $2;   # 250-XCLIENT/XFORWARD NAME ADDR PORT PROTO HELO IDENT SOURCE
    }
    if ($l=~/250[\s\-]+AUTH[\s\=]+(.+)/io) {
        my $methodes = $1;
        $methodes =~ s/^\s+//o;
        $methodes =~ s/[\s\r\n]+$//o;
        foreach (split(/\s+/o,$methodes)) {
            $Con{$cli}->{authmethodes}->{uc $_} = 1;
            d("info: replyEHLO: registered authmethode $_");
        }
    }
    if ($l=~/^5/o ||
        $l=~/^4/o ||
        $l=~/^221/o)
    {
        $this->{getline} = \&reply;
    } else {
        if (! $this->{answertToHELO} && $l =~ /^250\s+/o) {  # we've got the EHLO Reply, now send 250 OK to the client
            if ((exists $Con{$cli}->{XCLIENT} || exists $Con{$cli}->{XFORWARD}) &&
                ( ($Con{$cli}->{chainMailInSession} > 0 && $Con{$cli}->{lastcmd} =~ /mail from/io) ||
                  ($Con{$cli}->{lastcmd} =~ /helo|ehlo/io)
                )
               )
            {
                $this->{Xgetline} = \&replyEHLO;
                $this->{Xreply} = "250 OK\r\n";
                return if replyX($fh,$cli,$fh->peerhost(),$Con{$cli}->{ip});
                delete $this->{Xgetline};
                delete $this->{Xreply};
            }
            $this->{answertToHELO} = 1;
            sendque($cli,"250 OK\r\n");
            return;
        }
        sendque($cli,$l) if $this->{Xreply};
    }
}
