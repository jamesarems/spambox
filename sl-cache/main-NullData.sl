#line 1 "sub main::NullData"
package main; sub NullData { my ($fh,$l)=@_;
    d('NullData');
    if (! $Con{$fh}->{headerpassed}) {
        $Con{$fh}->{rcpt}=~s/\s+$//o;
        &allocateMemory($fh);
        MaillogStart($fh) if $Con{$fh}->{fakeAUTHsuccess}; # notify the stream logging to start logging
    }
    $Con{$fh}->{headerpassed} = 1;
    if ($Con{$fh}->{header} ne 'NULL') {
        $Con{$fh}->{header} .= $l;
        $Con{$fh}->{maillength} += length($l);
    }
    if ( $l =~ /^\.[\r\n]/ || defined( $Con{$fh}->{bdata} ) && $Con{$fh}->{bdata} <= 0 ) {
        if ($Con{$fh}->{fakeAUTHsuccess}) {
            $Con{$fh}->{deleteMailLog} = $Con{$fh}->{maillength} < 10;
            thisIsSpam($fh,'faked AUTH success SPAM collecting',$spamBucketLog,'',0,0,1); # collect the honeypot
            MaillogClose($fh);
            if  ($fakeAUTHsuccessSendFake && (my $mailfrom = $Con{$fh}->{mailfrom})) {
                my $header = $Con{$fh}->{header};
                $header =~ s/\r\n\.[\r\n]+$//o;
                $header =~ s/x-assp[^\r\n]+\r\n//goi;
                RCPT:
                for my $rcpt (split(/\s+/o,$Con{$fh}->{rcpt})) {
                    my ($domain) = $rcpt =~ /\@($EmailDomainRe)/io;
                    next RCPT unless $domain;
                    my $ans = queryDNS($domain ,'MX');
                    my @queryMX = ref($ans) ? sort { $a->preference <=> $b->preference } grep { $_->type eq 'MX'} $ans->answer
                                            : ();
                    next RCPT unless (@queryMX);
                    MXQ:
                    while (@queryMX) {
                        my $SMTP_HOSTNAME = eval{shift(@queryMX)->exchange;};
                        next MXQ unless $SMTP_HOSTNAME;

                        eval{
                        my $sender = Email::Send->new({mailer => 'SMTP'});
                        $sender->mailer_args([Host => $SMTP_HOSTNAME, Port => 25, Hello => $myName, NoTLS => 1, To => $rcpt, From => $mailfrom]);
                        eval{ require Email::Send::SMTP; } or last RCPT;
                        *{'Email::Send::SMTP::send'} = \&main::email_send_X;
                        $sender->send($header) &&
                        mlog(0,"send faked mail from $mailfrom to $rcpt via $SMTP_HOSTNAME");
                        } && next RCPT;
                    }
                }
            }
        }
        sendque($fh,"250 OK message queued\r\n");
        $Con{$fh}->{getline}=\&NullFromToData;
    }
}
