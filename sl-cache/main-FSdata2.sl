#line 1 "sub main::FSdata2"
package main; sub FSdata2 { my ($fh,$l)=@_;
    my $this=$Con{$fh};
    if($l=~/^ *[54]/o) {
        FSabort($fh,"FSdata2 Expected 354, got: $l");
    } elsif($l=~/^ *354 /o) {
        my $header;
        $header = $1 if $this->{body} =~ s/^($HeaderRe*)//os;
        $header =~ s/X-Assp[^():]+:$HeaderValueRe//gios;
        $this->{myheader}=~s/X-Assp-Intended-For:$HeaderValueRe//giso if $AddIntendedForHeader; # clear out existing X-Assp-Intended-For headers
        $header=~s/^($HeaderRe*)/$1From: sender not supplied\r\n/o unless $header=~/^$HeaderRe*From:/io; # add From: if missing
        $header=~s/^($HeaderRe*)/$1Subject:\r\n/o unless $header=~/^$HeaderRe*Subject:/io; # add Subject: if missing

        $this->{saveprepend}.=$this->{saveprepend2};
        $header=~s/^Subject:/Subject: $this->{saveprepend}/gim if ($spamTagCC && $this->{saveprepend} );

        $header=~s/^Subject:/Subject: $spamSubjectEnc/gimo if $spamSubjectCC && $spamSubjectEnc;

# remove Disposition-Notification headers if needed

        $header =~ s/(?:ReturnReceipt|Return-Receipt-To|Disposition-Notification-To):$HeaderValueRe//gios
            if ($removeDispositionNotification);
            
        # merge our header, add X-Intended-For header
        my ($to) = $this->{rcpt} =~ /(\S+)/o;
        $this->{myheader} .= "X-Assp-Intended-For: $to\r\n";
        $this->{myheader} .= "X-Assp-Copy-Spam: Yes\r\n";
        $this->{body} = $header.$this->{body};
        delete $this->{preheaderlength};
        $this->{addMyheaderTo} = 'body';
        addMyheader($fh);
        delete $this->{addMyheaderTo};
        delete $this->{preheaderlength};

        my $clamavbytes = $ClamAVBytes ? $ClamAVBytes : 50000;
        $clamavbytes = 100000 if $ClamAVBytes>100000;
        $this->{mailfrom} = $this->{from};
        $this->{ip} = $this->{fromIP};
        $this->{overwritedo} = 1;
        if ($ScanCC &&
                   $this->{body}  &&
                   ((haveToScan($fh) && ! ClamScanOK($fh,\substr($this->{body},0,$clamavbytes))) or
                    (haveToFileScan($fh) && ! FileScanOK($fh,\substr($this->{body},0,$clamavbytes)))
                   )
           ) {
           delete $this->{overwritedo};
           mlog($fh,"info: skip forwarding message to $this->{to_as} - virus found") if $ConnectionLog;
           @{$Con{$fh}->{to}} = (); undef @{$Con{$fh}->{to}};
           done2($fh);
           return;
        }
        delete $this->{overwritedo};
        $this->{body} =~ s/\r?\n/\r\n/gos;
        $this->{body} =~ s/[\r\n\.]+$//os;
        sendque($fh,$this->{body}) if $this->{body};
        sendque($fh,"\r\n.\r\n");
        delete $this->{body};
        mlog($fh,"info: message forwarded to $this->{to_as}") if $ConnectionLog;
        delete $this->{mailfrom};
        delete $this->{ip};
        $Con{$fh}->{getline}=\&FSquit;
    }
}
