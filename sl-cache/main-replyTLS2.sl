#line 1 "sub main::replyTLS2"
package main; sub replyTLS2 {
    d('replyTLS2');
    my ($fh,$l)=@_;
    d("lastReply2 = $l");
#    if (lc($l) eq lc($Con{$fh}->{lastEHLOreply}))
    my $cli = $Con{$fh}->{friend};

    $Con{$cli}->{inerror} = ($l=~/^5[05][0-9]/o);
    $Con{$cli}->{intemperror} = ($l=~/^4\d{2}/o);
    if ($l=~/^(?:1|2|3)\d{2}/o) {
        delete $Con{$cli}->{inerror};
        delete $Con{$cli}->{intemperror};
    }

    if ($l=~/250[\s\-]+AUTH[\s\=]+(.+)/io) {
        my $methodes = $1;
        $methodes =~ s/^\s+//o;
        $methodes =~ s/[\s\r\n]+$//o;
        foreach (split(/\s+/o,$methodes)) {
            $Con{$cli}->{authmethodes}->{uc $_} = 1;
            d("info: replyTLS2: registered authmethode $_");
        }
    }
    if ($l =~ /^250\s+/o) {
        my $ffr = $Con{$cli}->{TLSqueue};
        $Con{$fh}->{getline} = \&reply;
        &getline($cli,"$ffr\r\n");
        delete $Con{$cli}->{TLSqueue};
        my $serIP=$fh->peerhost().":".$fh->peerport();
        mlog($fh,"info: TLSQUEUE processed and cleared for $serIP") if ($ConnectionLog >=2);
    }
}
