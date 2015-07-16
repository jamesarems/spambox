#line 1 "sub main::done2"
package main; sub done2 {
    my $fh=shift;
    return unless $fh;
    $fh = $Con{$fh}->{self} if exists $Con{$fh}->{self};   # get the real filehandle
    my $oldfh = $Con{$fh}->{oldfh};
    my @handles;
    delete $Con{$fh}->{prepend};
    if (! exists $ConDelete{$fh}) {
        $ConDelete{$fh} = \&done2;
        if ($Con{$fh}->{type} eq 'C' && $Con{$fh}->{timestart}) {
            my $time=Time::HiRes::time() - $Con{$fh}->{timestart};
            $MailCount++;
            $MailCountTmp++;
            $MailTime = $MailTime + $time;
            $MailTimeTmp = $MailTimeTmp + $time;
            $MailProcTime = $MailProcTime + $time - $Con{$fh}->{damptime};
            $MailProcTimeTmp = $MailProcTimeTmp + $time - $Con{$fh}->{damptime};
        }
        if ($Con{$fh}->{type} eq 'C') {
            T10StatAdd($fh) if $DoT10Stat;
            done2($Con{$fh}->{friend})
              if ($Con{$fh}->{friend} &&
                  ! exists $ConDelete{$Con{$fh}->{friend}} &&
                  defined $Con{$Con{$fh}->{friend}} &&
                  length($Con{$Con{$fh}->{friend}}->{outgoing}) == 0);
        } else {
            if ($Con{$fh}->{friend} &&
                exists $Con{$Con{$fh}->{friend}} &&
                ! exists $ConDelete{$Con{$fh}->{friend}} &&
                $Con{$Con{$fh}->{friend}}->{lastcmd} =~ /DATA/i &&
                ! $Con{$Con{$fh}->{friend}}->{error} &&
                ! $Con{$Con{$fh}->{friend}}->{inerror} &&
                ! $Con{$Con{$fh}->{friend}}->{intemperror}
               )
            {
                my $ofh = $Con{$Con{$fh}->{friend}}->{self};
                $ofh ||= $Con{$fh}->{friend};
                $Con{$Con{$fh}->{friend}}->{deleteMailLog} = 'MTA closed connection';
                $Con{$Con{$fh}->{friend}}->{intemperror} = 1;
                $Con{$Con{$fh}->{friend}}->{closeafterwrite} = 1;
                mlog($ofh,"info: server has closed the connection without sending a reply - classify mail as rejected by MTA") if $ConnectionLog;
                sendque($ofh,"451 Requested action aborted: local error in processing\r\n");
            }
        }
        return;
    }
    push @handles, $fh;
    if ($oldfh && ! exists $ConDelete{$oldfh}) {
        delete $Con{$oldfh}->{timestart};
        push @handles, $oldfh;
    }
    d('done2');
    while (@handles) {
        my $fh = shift @handles;
        next unless $fh;
        removeCrashFile($fh);
        mlog(0,"info: unable to close \$fh == '$fh'") unless $fh;
        $Con{$Con{$fh}->{forwardSpam}}->{gotAllText} = 1 if $Con{$fh}->{forwardSpam} && exists $Con{$Con{$fh}->{forwardSpam}};
        threadConDone($fh);
        delete $dampedFH{$fh};

        delete $Con{$fh}->{prepend};

        if (   $Con{$fh}->{type} eq 'C'   # remove MaillogFile for possily incomplete transmitted mails
            && ! $Con{$fh}->{spamfound}
            && ! $Con{$fh}->{error}
            && lc($Con{$fh}->{lastcmd}) ne 'quit'
            && $Con{$fh}->{maillogfh}
            && $Con{$fh}->{maillogfilename}
            && ! $Con{$fh}->{deleteMailLog}
           )
        {
            $Con{$fh}->{deleteMailLog} = 'incomplete good mail';
            mlog(0,"info: will remove file '$Con{$fh}->{maillogfilename}' , because mail delivery was incomplete for a good mail") if $ConnectionLog;
        }

        my $ip=$Con{$fh}->{ip};
        my $cmdlist = @{$Con{$fh}->{cmdlist}} ? "\'".join("," , @{$Con{$fh}->{cmdlist}})."\'" : "\'n/a\'";
        @{$Con{$fh}->{sip}} = (); undef @{$Con{$fh}->{sip}};
        @{$Con{$fh}->{senders}} = (); undef @{$Con{$fh}->{senders}};
        @{$Con{$fh}->{cmdlist}} = (); undef @{$Con{$fh}->{cmdlist}};
        @{$Con{$fh}->{AUTHClient}} = (); undef @{$Con{$fh}->{AUTHClient}};
        @{$Con{$fh}->{trapaddr}} = (); undef @{$Con{$fh}->{trapaddr}};
        %{$Con{$fh}->{rcptlist}} = (); undef %{$Con{$fh}->{rcptlist}};
        %{$Con{$fh}->{authmethodes}} = (); undef %{$Con{$fh}->{authmethodes}};
        %{$Con{$fh}->{userauth}} = (); undef %{$Con{$fh}->{userauth}};
        %{$Con{$fh}->{Xheaders}} = (); undef %{$Con{$fh}->{Xheaders}};

        $cmdlist = $ConnectionLog >= 2 ? "- command list was $cmdlist" : '';
        if ($ip &&
            $ConnectionLog &&
            !(matchIP($ip,'noLog',0,1)) &&
            (($Con{$fh}->{movedtossl} && "$fh" =~/SSL/io) or (!$Con{$fh}->{movedtossl})))
        {
            $Con{$fh}->{writtenDataToFriend} -= 6;
            $Con{$fh}->{writtenDataToFriend} = 0 if $Con{$fh}->{writtenDataToFriend} < 0;
            my $sz = max($Con{$fh}->{spambuf},$Con{$fh}->{mailloglength});
            $sz = $Con{$fh}->{maillength} unless $sz;
            mlog(0, 'finished message - received DATA size: ' . &formatNumDataSize($sz) . ' - sent DATA size: ' . &formatNumDataSize($Con{$fh}->{writtenDataToFriend}))
                if ($Con{$fh}->{maillength} > 3);
            my $sc;
            $sc = " - used $Con{$fh}->{socketcalls} SocketCalls " if $ConnectionLog >= 2 && $Con{$fh}->{socketcalls};
            my $ptime = $Con{$fh}->{timestart} ? time - $Con{$fh}->{timestart} : 0;
            $Con{$fh}->{damptime} ||= 0 if $DoDamping;
            delete $Con{$fh}->{damptime} if $ConnectionLog < 2 or $Con{$fh}->{relayok};
            my $dtime = exists $Con{$fh}->{damptime} ? " - damped $Con{$fh}->{damptime} seconds" : '';
            mlog(0, "disconnected: session:$Con{$fh}->{SessionID} $ip $cmdlist$sc- processing time $ptime seconds$dtime",1);
        }
        d('closing maillogfh');

        # close the maillog if it's still open
        &MaillogClose($fh);

        my $what = ($Con{$fh}->{type} eq 'C') ? 'client' : 'server';
        d("closing $what $fh $ip");
        # close it
        if ("$fh" =~ /SSL/io) {
            eval{close($fh);};
            if ($@) {
                mlog(0,"warning: unable to close $fh - $@");
                eval{IO::Socket::SSL::kill_socket($fh)};
                if ($@) {
                    mlog(0,"warning: unable to kill $fh - $@");
                }
            }
        } else {
            eval{close($fh) if fileno($fh);};
        }

        d('delete the Connection data');
        # delete the Connection data
        delete $Con{$fh};
        delete $ConDelete{$fh};

        d('delete the Session data');
        # delete the Session data.
        if (exists $SMTPSession{$fh}) {
            delete $SMTPSession{$fh};
            threads->yield;
            $smtpConcurrentSessions = 0 if (--$smtpConcurrentSessions < 0);
            threads->yield;
            $SMTPSessionIP{Total}-- ;
            threads->yield;
            delete $SMTPSessionIP{$ip} if (--$SMTPSessionIP{$ip} <= 0);
            threads->yield;
        }
        d('finished closing connection');
    }
    undef %Con unless keys(%Con);
    undef %ConDelete unless keys(%ConDelete);
    undef %SocketCalls unless keys(%SocketCalls);
    undef %SocketCallsNewCon unless keys(%SocketCallsNewCon);
}
