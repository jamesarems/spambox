#line 1 "sub main::Maillog"
package main; sub Maillog {
    my ( $fh, $text, $parm ) = @_;
    my $fln;
    my $isnotcc = 0;
    d('Maillog');
    return unless $fh;

# $parm meanings
# 0 -- no collection,
# 1 -- is spam,
# 2 -- not spam,
# 3 -- is spam && cc to spamaccount,
# 4 -- mail ok,
# 5 -- viruses
# 6 -- discard folder,
# 7 -- discard folder && cc to spamaccount

    my $p = {
        'nocol'  => 0,
        'spam'   => 1,
        'ham'    => 2,
        'spamcc' => 3,
        'ok'     => 4,
        'virus'  => 5,
        'dis'    => 6,
        'discc'  => 7,
    };

    if ( $parm == $p->{spam} ) {
        $parm    = $p->{spamcc};
        $isnotcc = 1;
    }
    if ( $parm == $p->{dis} ) {
        $parm    = $p->{discc};
        $isnotcc = 1;
    }

    $isnotcc ||= 1 if $Con{$fh}->{ccnever};   # do not copy mail
    $isnotcc ||= 1 if ($ccMaxScore && ($parm == $p->{spamcc} || $parm == $p->{discc}) && $Con{$fh}->{messagescore} > $ccMaxScore );

    return if ( $parm == $p->{ham} || $parm == $p->{ok} ) && $Con{$fh}->{red} && $DoNotCollectRedRe;
    return if ( ! $Con{$fh}->{maillog} );
    return if ( $Con{$fh}->{nocollect} );
    return if $Con{$fh}->{isbounce} && $DoNotCollectBounces;
    return if $Con{$fh}->{noprocessing} && ( $parm == $p->{ham} || $parm == $p->{ok} ) && ! $noProcessingLog;

    if ($parm == $p->{spamcc}) {
        $parm = $p->{discc} if $Con{$fh}->{noprocessing};
        $parm = $p->{discc} if $Con{$fh}->{red} && $DoNotCollectRedRe;
        $parm = $p->{discc} if $Con{$fh}->{messagelow};
        $parm = $p->{discc} if ($Con{$fh}->{redsl} & 1);
    }

    if ($isnotcc && $parm == $p->{discc}) {
        $isnotcc = 0 if ($ccSpamAlways && allSL( $Con{$fh}->{rcpt}, $Con{$fh}->{mailfrom}, 'ccSpamAlways' ) );
        $isnotcc = 0 if ($ccSpamFilter && $sendAllSpam && allSL( $Con{$fh}->{rcpt}, $Con{$fh}->{mailfrom}, 'ccSpamFilter' ) );
    }
    $parm = $p->{discc} if (($Con{$fh}->{redsl} & 1) && $parm == $p->{ham});

    my $skipLog = 0;
    if ( $parm == $p->{ham} || $parm == $p->{spamcc} ) {
        threads->yield();
        if ( ++$logCount[$parm] < $logFreq[$parm] ) {
            $skipLog = 1;
        } else {
            threads->yield();
            $logCount[$parm] = 0;
        }
    }

    if ( $parm == $p->{spamcc} && $skipLog ) {   # write spam to discarded for blockreports
        $parm    = $p->{discc};
        $skipLog = 0;
    }

    my $mFolder;
    if (   $parm == $p->{ok}     && ! $incomingOkMail                && ($mFolder = "incomingOkMail($incomingOkMail)")
    	|| $parm == $p->{spamcc} && (! $spamlog || ! $SpamLog)       && ($mFolder = "spamlog($spamlog) SpamLog($SpamLog)")
        || $parm == $p->{ham}    && (! $notspamlog || ! $NonSpamLog) && ($mFolder = "notspamlog($notspamlog) NonSpamLog($NonSpamLog)")
        || $parm == $p->{virus}  && ! $viruslog                      && ($mFolder = "viruslog($viruslog)")
        || $parm == $p->{discc}  && ! $discarded                     && ($mFolder = "discarded($discarded)")
        || $skipLog ) {
        $mFolder = " missing folder ($parm - $mFolder)" if $mFolder;
        $mFolder .= " skiplog condition found" if $skipLog;
        d("Maillog - no log -$mFolder");
        mlog($fh,"info: Maillog - no log -$mFolder") if $SessionLog > 2;
        $text = $Con{$fh}->{maillogbuf} . $text;
        delete $Con{$fh}->{maillog};
        close $Con{$fh}->{maillogfh} if $Con{$fh}->{maillogfh};
        delete $Con{$fh}->{maillogfh};
        delete $Con{$fh}->{mailloglength};
        if ($Con{$fh}->{maillogfilename}) {$unlink->($Con{$fh}->{maillogfilename}); delete $Con{$fh}->{maillogfilename};}
    } elsif ( $parm  ) {

        d('Maillog - log '.$parm);

        # we now know if it is spam or not -- open the file
        $text = $Con{$fh}->{maillogbuf} . $text;

        &sigoffTry(__LINE__);
        if ($Con{$fh}->{maillogfh}) {eval{$Con{$fh}->{maillogfh}->close;}; delete $Con{$fh}->{maillogfh};}
        $Con{$fh}->{maillogfilename} && $eF->($Con{$fh}->{maillogfilename}) && $unlink->($Con{$fh}->{maillogfilename});
        $fln = $Con{$fh}->{maillogfilename} = maillogFilename( $fh, $parm );
        if ( ! $fln ) {
            $Con{$fh}->{maillogfilename} = $fln = '';
        } elsif ( $Con{$fh}->{red} && $DoNotCollectRedRe ) {
            $Con{$fh}->{maillogfilename} = $fln = '';
            mlog($fh,"info: Maillog - no log - because DoNotCollectRedRe") if $SessionLog > 2;
        } else {
            $eF->($Con{$fh}->{maillogfilename}) and $unlink->($Con{$fh}->{maillogfilename});
            if ($open->(my $FH, '>',$fln )) {
                $FH->binmode;
                $Con{$fh}->{maillogfh} = $FH;
                $Con{$fh}->{mailloglength} = 0;
                if ($StoreSPAMBOXHeader) {
                    my $myheader = $Con{$fh}->{myheader};
                    $myheader = "X-Assp-Version: $version$modversion on $myName\r\n" . $myheader
                        if $myheader !~ /X-Assp-Version:.+? on \Q$myName\E/;
                    $myheader .= "X-Assp-ID: $myName $Con{$fh}->{msgtime}\r\n"
                        if $myheader !~ /X-Assp-ID: \Q$myName\E/;
                    $myheader .= "X-Assp-Session: $Con{$fh}->{SessionID}\r\n"
                        if $myheader !~ /X-Assp-Session:/o;
                    $myheader =~ s/X-Assp-Spam:$HeaderValueRe//gios;
                    $myheader =~ s/X-Assp-Spam-Level:$HeaderValueRe//gios;
                    $myheader =~ s/[\r\n]+$/\r\n/o;
                    $myheader = headerFormat($myheader);
                    $FH->print($myheader);
                    $Con{$fh}->{mailloglength} = length($myheader);
                }
            } else {
                mlog( $fh, "error: can't open maillog '".de8($fln)."': $!" );
                $Con{$fh}->{maillogfilename} = $fln = '';
            }
        }
        &sigonTry(__LINE__);
    } elsif ($parm eq '0') {
        my ($package, $file, $line) = caller;
        d("Maillog - no log - log-condition is \'$parm - no collection\' - $package, $file, $line");
        mlog($fh,"info: Maillog - no log - log-condition is \'$parm - no collection\'") if $SessionLog > 2;
    }

    if (! $Con{$fh}->{storecompletemail} ) {
        $Con{$fh}->{storecompletemail} = $StoreCompleteMail;
        $Con{$fh}->{storecompletemail} = 999999999 if !$StoreCompleteMail && $Con{$fh}->{alllog};
        $Con{$fh}->{storecompletemail} = 999999999 if $ccSpamAlways && allSL( $Con{$fh}->{rcpt}, $Con{$fh}->{mailfrom}, 'ccSpamAlways' );
    }

    # start sending the message to sendAllSpam if appropriate

    if (   ($sendAllSpam or scalar keys %ccdlist)
        && ! $Con{$fh}->{forwardSpam}
        && ! $isnotcc
        && ($parm == $p->{spamcc} || $parm == $p->{discc})
        && (! $ccSpamFilter || $ccSpamFilter && allSL($Con{$fh}->{rcpt},$Con{$fh}->{mailfrom},'ccSpamFilter')) )
    {
        my %cc;
        for (split(/\s+/,lc $Con{$fh}->{rcpt})) {
            /($EmailAdrRe)\@($EmailDomainRe)/o or next;
            my ($current_username,$current_domain) = ($1,$2);
            my $ccspamlt = $sendAllSpam;
            if ($ccspamlt) {
                $ccspamlt =~ s/USERNAME/$current_username/go;
                $ccspamlt =~ s/DOMAIN/$current_domain/go;
                $cc{$ccspamlt} = 1;
            }
            if ( exists $ccdlist{$current_domain} ) {
                $cc{$ccdlist{$current_domain} . '@' . $current_domain} = 1;
            } elsif (exists $ccdlist{'*'}) {
            	$cc{$ccdlist{'*'}.'@'.$current_domain} = 1;
            }
        }
        $Con{$fh}->{forwardSpam} = forwardSpam($Con{$fh}->{mailfrom},join(' ',keys(%cc)),$fh) if (scalar keys(%cc));
    }

    my $gotAllText;
    if(my $h = $Con{$fh}->{maillogfh}) {
        if (! $Con{$fh}->{spambuf}) {
            $h->print(substr($text,0,max($Con{$fh}->{storecompletemail},$MaxBytes)));
            $Con{$fh}->{mailloglength} = $Con{$fh}->{spambuf} = length($text);
            $Con{$fh}->{maillogbuf} = $text;
        } else {
            if ( $Con{$fh}->{spambuf} < $Con{$fh}->{storecompletemail}) {
                $h->print(substr($text,0,$Con{$fh}->{storecompletemail} - $Con{$fh}->{spambuf}));
            } else {
                $h->print(substr($text,0,$MaxBytes + $Con{$fh}->{headerlength})) if $Con{$fh}->{spambuf}<$MaxBytes + $Con{$fh}->{headerlength} ;
            }
            $Con{$fh}->{maillogbuf}.=$text;
            $Con{$fh}->{spambuf} += length($text);
            $Con{$fh}->{mailloglength} = length($Con{$fh}->{maillogbuf});
        }
        if(  (   $ccMaxBytes
              && $Con{$fh}->{mailloglength} > $MaxBytes + $Con{$fh}->{headerlength}
              && $Con{$fh}->{mailloglength} > $Con{$fh}->{storecompletemail})
           || $text=~/(^|[\r\n])\.[\r\n]/o || $Con{$fh}->{logalldone})
        {
            d('Maillog - no cc');
            $gotAllText = 1;
            $h->close;
            undef $h;
            delete $Con{$fh}->{maillog} unless $Con{$fh}->{forwardSpam};
            unless (keys %runOnMaillogClose) {
                delete $Con{$fh}->{maillogfh};
                delete $Con{$fh}->{mailloglength};
                delete $Con{$fh}->{maillogfilename};
            }
        }
    } elsif(! $ccMaxBytes || $Con{$fh}->{mailloglength} < $MaxBytes + $Con{$fh}->{headerlength} || $Con{$fh}->{mailloglength} < $Con{$fh}->{storecompletemail}) {
        $Con{$fh}->{maillogbuf}.=$text;
        $Con{$fh}->{mailloglength} = length($Con{$fh}->{maillogbuf});
    }
    if($Con{$fh}->{forwardSpam} && exists $Con{$Con{$fh}->{forwardSpam}} && exists $Con{$Con{$fh}->{forwardSpam}}->{body}) {
        $Con{$Con{$fh}->{forwardSpam}}->{body} .= $text;
        $Con{$Con{$fh}->{forwardSpam}}->{gotAllText} = $gotAllText;
    }
    return $fln;
}
