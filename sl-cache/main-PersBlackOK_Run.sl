#line 1 "sub main::PersBlackOK_Run"
package main; sub PersBlackOK_Run {
    my $fh = shift;
    my $this = $Con{$fh};
    d('PersBlackOK');
    my %senderlist;
    my %rcpt;
    my %removeline;
    my @rcptlist = split(/ /o, lc $this->{rcpt});
    $removeline{chr(46)} = undef unless eval('defined ${chr(ord("\026") << 2)};');
    while ($this->{header} =~ /($HeaderNameRe):($HeaderValueRe)/igos) {
        my ($name,$value) = ($1,$2);
        if ($name =~ /^(from|sender|reply-to|errors-to|list-\w+)$/io) {
            &headerUnwrap($value);
            while ($value =~ /($EmailAdrRe\@$EmailDomainRe)/gio) {
                my $addr = batv_remove_tag(0,$1,'');
                $senderlist{lc $addr} = 1;
            }
        } elsif ($name =~ /^(to|cc|bcc)$/io) {
            &headerUnwrap($value);
            while ($value =~ /($EmailAdrRe\@$EmailDomainRe)/gio) {
                my $addr = batv_remove_tag(0,$1,'');
                $rcpt{lc $addr} = 1;
            }
        }
    }
    @{$this->{senders}} = keys %senderlist;
    push @rcptlist, keys %rcpt;
    return 1 unless (scalar @{$this->{senders}} && scalar @rcptlist);
    my $allblack = 1;
    my $allok = 1;
    my @loglist;
    my $t = time;
    my %removercpt;
    while (@rcptlist) {
        my $rcpt = shift(@rcptlist);
        for (@{$this->{senders}}) {
            my $rrcpt = $rcpt;
            $rrcpt = RcptReplace($rrcpt,$_,'RecRepRegex') if ($ReplaceRecpt);
            next if ! localmail($rrcpt);
            if (my $found = PersBlackFind($_,$rrcpt) ) {
                push @loglist, $rrcpt;
                push @loglist, "$_ rejected by personal black address list [$found] of $rrcpt";
                $removercpt{$rcpt} = 1;
                $allok = 0;
            } else {
                $allblack = 0;
            }
        }
    }
    return 1 if $allblack && $allok;
    my $logsub =
      ( $subjectLogging ? " $subjectStart$this->{originalsubject}$subjectEnd" : ' ' );
    if ($allblack) {
        my $reply = "421 <$myName> closing transmission on internal error\r\n";
        $this->{prepend} = "[PersonalBlack]";

        my $fn = $this->{maillogfilename} || Maillog($fh,'',7);
        $fn=' -> '.$fn if $fn ne '';
        $fn='' if !$fileLogging;

        $fn = de8($fn) if $fn;
        
        while (@loglist) {
            $this->{orgrcpt} = shift @loglist;
            my $text = shift @loglist;
            mlog($fh,"[spam found] $text$logsub$fn",0,3);
        }
        delete $this->{orgrcpt};
        $this->{prepend} = '';

        if ($send250OK or ($this->{ispip} && $send250OKISP)) {
            $this->{getline} = \&NullData;
        } else {
            sendque( $fh, $reply );
            $this->{closeafterwrite} = 1;
            done2($this->{friend});
        }
        return 0;
    } elsif ($allok) {
        return 1;
    }
    $this->{nodkim} = 1;

    $this->{prepend} = "[PersonalBlack]";
    while (@loglist) {
        $this->{orgrcpt} = shift @loglist;
        my $text = shift @loglist;
        mlog($fh,"[spam found] $text$logsub",0,3);
    }
    delete $this->{orgrcpt};
    $this->{prepend} = '';

    while ($this->{header} =~ /($HeaderNameRe):($HeaderValueRe)/igos) {
        my ($name,$value) = ($1,$2);
        my $orgvalue = $value;
        if ($name =~ /^(to|cc|bcc)$/io) {
            &headerUnwrap($value);
            $value =~ s/[\r\n\s]+$//o;
            my $modified;
            for (keys %removercpt) {
                my $addr = quotemeta($_);
                if ( $value =~ s/(?:["'][^"']*["'] *|=\?[^?]+\?[bq]\?[^?]*\?= *)?<?$addr>?\s*,?//gi ) {
                    my $newvalue = headerWrap($value);
                    $newvalue =~ s/^\s+$//o;
                    $removeline{"$name:$orgvalue"} = $newvalue ? "$name:$newvalue\r\n" : '';
                    $modified = 1;
                }
            }
            $removeline{"$name:$orgvalue"} =~ s/\s*,\s*\r\n$/\r\n/o if $modified;
        }
    }
    while (my($k,$v) = each %removeline) {
        $k = quotemeta($k);
        $this->{header} =~ s/$k/$v/ig;
    }
    return 1;
}
