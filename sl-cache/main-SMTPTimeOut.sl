#line 1 "sub main::SMTPTimeOut"
package main; sub SMTPTimeOut {
    my $sfh = shift;
    if ($smtpIdleTimeout > 0 || $smtpNOOPIdleTimeout > 0){
        if (scalar keys %Con > 0){
            my $tmpNow = time;
            # Check timeouts only every 15 seconds at least
            if ($tmpNow > ($lastTimeoutCheck + 15)){
                while (my ($tmpfh,$v) = each %Con){
                    next if("$tmpfh" eq "$sfh");
                    delete $Con{$tmpfh}->{doNotTimeout} if ($tmpNow - $Con{$tmpfh}->{doNotTimeout} > $NpWlTimeOut);
                    if ($Con{$tmpfh}->{type} =~ /CC?/o &&
                        $Con{$tmpfh}->{timelast} > 0 &&
                        ! $Con{$tmpfh}->{movedtossl} &&
                        ! $Con{$tmpfh}->{doNotTimeout} &&
                        ! (($Con{$tmpfh}->{noprocessing} || $Con{$tmpfh}->{whitelisted}) && $tmpNow - $Con{$tmpfh}->{timelast} < $NpWlTimeOut) &&   # 20 minutes for realy large queued mails
                        (($smtpIdleTimeout && $tmpNow - $Con{$tmpfh}->{timelast} > $smtpIdleTimeout) ||
                          (uc($Con{$tmpfh}->{lastcmd}) =~ /NOOP/o &&
                          $smtpNOOPIdleTimeout &&
                          $tmpNow - $Con{$tmpfh}->{timelast} > $smtpNOOPIdleTimeout) ||
                          ($smtpNOOPIdleTimeout &&
                          $smtpNOOPIdleTimeoutCount &&
                          $Con{$tmpfh}->{NOOPcount} >= $smtpNOOPIdleTimeoutCount))
                        )
                    {
                        if ($ConTimeOutDebug) {
                           my $m = &timestring();
                           $Con{$tmpfh}->{contimeoutdebug} .= "$m client Timeout after $smtpIdleTimeout secs\r\n" if $ConTimeOutDebug;
                           my $check = "$m client was not readable\r\n";
                           my @handles = $readable->handles();
                           while (@handles) {
                              $_ = shift @handles;
                              $check = "$m client was readable\r\n" if ($tmpfh eq $_);
                           }
                           $Con{$tmpfh}->{contimeoutdebug} .= $check;
                           $check = "$m client was not writable\r\n";
                           @handles = $writable->handles();
                           while (@handles) {
                              $_ = shift @handles;
                              $check = "$m client was writable\r\n" if ($tmpfh eq $_);
                           }
                           $Con{$tmpfh}->{contimeoutdebug} .= $check;
                           $m=time;
                           my $f = "$base/debug/$m.txt";
                           my $CTOD;
                           open $CTOD,'>',"$f" or mlog(0,"error: unable to open connection timeout debug log [$f] : $!");
                           binmode $CTOD;
                           print $CTOD  $Con{$tmpfh}->{contimeoutdebug};
                           close $CTOD;
                        }
                        $Con{$tmpfh}->{prepend}='';
                        $Con{$tmpfh}->{timestart} = 0;
                        my $type;
                        my $addPB = 0;
                        if ($Con{$tmpfh}->{oldfh} && $Con{$tmpfh}->{ip}) {
                            setSSLfailed($Con{$tmpfh}->{ip});
                            $type = 'TLS-';
                            $Stats{smtpConnTLSIdleTimeout}++;
                        } elsif ("$tmpfh" =~/SSL/io && $Con{$tmpfh}->{ip}) {
                            $type = 'SSL-';
                            $Stats{smtpConnSSLIdleTimeout}++;
                        } else {
                            $addPB = 1;
                            $Stats{smtpConnIdleTimeout}++;
                        }
                        if ($Con{$tmpfh}->{damping}) {
                            $Con{$tmpfh}->{messagescore} = 0;
                            delete $ConDelete{$tmpfh};
                            $addPB = 0;
                        }
                        if ( ! $Con{$tmpfh}->{timedout} ) {
                            pbAdd( $tmpfh,$Con{$tmpfh}->{ip}, 'idleValencePB', "TimeOut",2 ) if $addPB;
                            mlog($tmpfh,$type."Connection idle for $smtpIdleTimeout secs - timeout",1) if $SessionLog;
                        } else {
                            done($Con{$tmpfh}->{client});
                            next;
                        }
                        $Con{$tmpfh}->{timedout} = 1;
                        if ($Con{$tmpfh}->{getline} != \&error) {
                            seterror($Con{$tmpfh}->{client},"451 Connection timeout, try later\r\n",1);
                        } else {
                            if (! $Con{$tmpfh}->{closeafterwrite}) {
                                sendque($Con{$tmpfh}->{client},"451 Connection timeout, try later\r\n");
                                $Con{$tmpfh}->{closeafterwrite} = 1;
                                unpoll($Con{$tmpfh}->{client}, $readable);
                            } else {
                                done($Con{$tmpfh}->{client});
                            }
                        }
                    }
                }
                $lastTimeoutCheck = $tmpNow;
            }
        }
    }
}
