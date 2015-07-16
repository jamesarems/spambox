#line 1 "sub main::DKIMgen_Run"
package main; sub DKIMgen_Run {
    my $fh = shift;
    my $this = $Con{$fh};
    my $domain;
    my $dkim;
    my $signature;
    my $sigobj;
    my $headlen;
    my $numSelectors;
    my $Selector;
    our %DKIM;
    my @Headers;
    my $mode = 'DKIM';
    my $policyfn;
    
    d('DKIMgen');
    return unless $CanUseDKIM;
    return unless $genDKIM;
    return unless $this->{relayok};
    return if $this->{DKIMadded};

    while ($this->{header} =~ /($HeaderNameRe):($HeaderValueRe)/igos) {

        next if lc($1) ne 'from';
        my $s = $2;
        &headerUnwrap($s);
        if ($s =~ /$EmailAdrRe\@($EmailDomainRe)/io) {
            $domain = $1;
            last;
        }
    }

    ($domain) = $this->{mailfrom} =~ /^[^@]+\@([^@]+)$/o unless $domain;
    return unless $domain;
    $domain = lc($domain);
    return unless exists $DKIMInfo{$domain};
    
    $numSelectors = scalar(keys %{$DKIMInfo{$domain}});
    return unless $numSelectors;

    my $sel = int(rand($numSelectors));
    
    my $i = 0;
    foreach my $s (keys %{$DKIMInfo{$domain}}) {
        $Selector = $s;
        last if($i == $sel);
        $i++;
    }

    $DKIM{Selector} = $Selector;
    $DKIM{Domain} = $domain;
    mlog(0,"DKIM: Selector = $Selector") if $DKIMlogging == 3 or $debug or $ThreadDebug;
    mlog(0,"DKIM: Domain = $domain") if $DKIMlogging == 3 or $debug or $ThreadDebug;

    while ( my ($k,$v) = each %{$DKIMInfo{$domain}->{$Selector}}) {
        mlog(0,"DKIM: $k = $v") if $DKIMlogging == 3 or $debug or $ThreadDebug;
        if (lc $k eq 'mode') {
            $mode = $v;
            $mode = 'DKIM' if (uc $mode eq 'DKIM');
            $mode = 'Domainkey' if (uc $mode eq 'DOMAINKEY');
            next;
        }
        $DKIM{$k} = $v;
    }
    eval { $Mail::DKIM::DNS::RESOLVER = getDNSResolver(); };

    if ($mode eq 'Domainkey') {
        $policyfn =
            sub {
                my $dkimp = shift;
                $dkimp->add_signature(Mail::DKIM::DkSignature->new(%main::DKIM));
                return 1;
            };
    } else {
        $policyfn =
            sub {
                my $dkimp = shift;
                $dkimp->add_signature(Mail::DKIM::Signature->new(%main::DKIM));
                return 1;
            };
    }

    $DKIM{Policy} = $policyfn;

    eval{$dkim = Mail::DKIM::Signer->new(%DKIM);};
    if(! $dkim ) {
        mlog($fh,"error: DKIM primary signer object failed - $@") if $DKIMlogging;
        return;
    }

    $this->{header} =~ s/\015?\012\.[\015\012]*$/\015\012\.\015\012/o;

    if($DKIMconvHTML2base64 && $this->{header}=~ /\015\012\Content-Type:\s*text\/(?:ht|x)ml/sio) {
        my $converted = 0;
        $o_EMM_pm = 1;
        eval {   # HTML message hack (eg. MSOL2007)- convert any text/html content to base64
            my @newparts;
            $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
            my $email = Email::MIME->new($this->{header});
            foreach my $part ( $email->parts ) {
              if ($part->parts > 1) {
                $part->walk_parts(sub {
                my ($subpart) = @_;
                if ($subpart->header("Content-Type")=~/text\/(?:ht|x)ml/io &&
                    $subpart->header("Content-Transfer-Encoding")!~/base64/io)
                {
                    $subpart->encoding_set('base64');
                    $converted = 1;
                }
                });
              } else {
                if ($part->header("Content-Type")=~/text\/(?:ht|x)ml/io &&
                    $part->header("Content-Transfer-Encoding")!~/base64/io)
                {
                    $part->encoding_set('base64');
                    $converted = 1;
                }
              }
              push @newparts, $part;
            }
            if ($converted) {
                $email->header_set('MIME-Version', '1.0') if !$email->header('MIME-Version');
                $email->parts_set(\@newparts);
                $this->{header} = $email->as_string;
            }
            undef @newparts;
            undef $email;
        };
        $o_EMM_pm = 0;
        if ($@) {
            mlog($fh,"warning: HTML message could not be encoded to base64 - DKIM signature may fail - $@");
        } elsif ($converted) {
            mlog($fh,"info: HTML message encoded for DKIM to base64") if $DKIMLog >= 2;
        }
        $this->{header} =~ s/\x0D([^\x0A])/\x0D\x0A$1/go;
        $this->{header} =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;   # make LF CR RFC conform
        $this->{header} .= "\x0D\x0A.\x0D\x0A" if ($this->{header} !~ /\x0D\x0A\.\x0D\x0A$/o);
    }

    eval{
     for my $msgLine (split(/\n/o, $this->{header})) {
         $msgLine =~ s/^\.([^\015]+\015)$/$1/o;
         $dkim->PRINT("$msgLine\n") if ($msgLine !~ /^\.\015$/o);
     }
     $dkim->CLOSE;
    };
    if( $@ ) {
        mlog($fh,"error: $mode message parsing failed - $@") if $DKIMlogging;
        return;
    }
    eval{ $sigobj = $dkim->signature;};
    if(! $sigobj ) {
         my $result = $dkim->result;
         my $result_detail = $dkim->result_detail;
         my $attr = join(", ", $dkim->message_attributes);
         mlog($fh,"error: $mode get signature object failed - $@ - $result - $result_detail - $attr") if $DKIMlogging;
         return;
    }
    eval{ $signature = $sigobj->as_string;};
    if(! $signature ) {
         my $result = $dkim->result;
         my $result_detail = $dkim->result_detail;
         my $attr = join(", ", $dkim->message_attributes);
         mlog($fh,"error: $mode get signature failed - $@ - $result - $result_detail - $attr") if $DKIMlogging;
         return;
    }
    d($signature);
    $signature =~ s/([^\015][^\012])$/$1\015\012/o;
    $this->{header} = &headerWrap($signature) . $this->{header};
    mlog($fh,"info: successful added $mode-Signature") if($DKIMlogging >= 2);
    $this->{DKIMadded} = 1;

    if ($DKIMlogging > 2) {
        my $dkim = Mail::DKIM::Verifier->new();
        for my $msgLine (split(/\n/o, $this->{header}))
        {
           $msgLine =~ s/^\.([^\015]+\015)$/$1/o;
           $dkim->PRINT("$msgLine\n") if ($msgLine !~ /^\.\015$/o);
        }
        $dkim->CLOSE;
        my $result = $dkim->result;
        my $detail = $dkim->result_detail;
        my $dkimpolicy_a  = $dkim->fetch_author_policy;
        my $dkimwhy_a     = $dkimpolicy_a->apply($dkim);
        my $dkimpolicy_s  = $dkim->fetch_sender_policy;
        my $dkimwhy_s     = $dkimpolicy_s->apply($dkim);

        mlog($fh,"DKIM: self signature check: result: $result - detail: $detail");
    }
    return;
}
