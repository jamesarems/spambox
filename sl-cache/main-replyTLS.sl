#line 1 "sub main::replyTLS"
package main; sub replyTLS {
    d('replyTLS');
    my ($fh,$l)=@_;
    my $oldfh = "$fh";
    my $ssl;
    my $cli = $Con{$fh}->{friend};
    my $serIP=$fh->peerhost();
    my $ffr = $Con{$cli}->{TLSqueue};

    $Con{$cli}->{inerror} = ($l=~/^5[05][0-9]/o);
    $Con{$cli}->{intemperror} = ($l=~/^4\d{2}/o);
    if ($l=~/^(?:1|2|3)\d{2}/o) {
        delete $Con{$cli}->{inerror};
        delete $Con{$cli}->{intemperror};
    }

    if($l=~/^220/o) { # we can switch the server connection to TLS
        $IO::Socket::SSL::DEBUG = $SSLDEBUG;
        unpoll($fh,$readable);
        unpoll($fh,$writable);
        my $fail = 0;
        eval{eval{($ssl,$fh) = &switchSSLServer($fh);};
            if ("$ssl" !~ /SSL/io) {
              $fail = 1;
              mlog($fh, "error: Couldn't start TLS for server $serIP: ".IO::Socket::SSL::errstr());
              setSSLfailed($serIP);
              delete $Con{$fh}->{fakeTLS};
              &dopoll($fh,$readable,POLLIN);
              &dopoll($fh,$writable,POLLOUT);
              # process TLSqueue on client
              &getline($cli,$ffr);
              delete $Con{$cli}->{TLSqueue};
              $Con{$fh}->{getline}=\&reply;
            }
        };
        return if $fail;
        delete $SSLfailed{$serIP};
        addsslfh($oldfh,$ssl,$cli);
        $Con{$cli}->{friend} = $ssl;
        mlog($ssl,"info: started TLS-SSL session for server $serIP") if ($ConnectionLog >=2);
        delete $Con{$oldfh}->{fakeTLS};
        delete $Con{$ssl}->{fakeTLS};
        NoLoopSyswrite($ssl,"$Con{$cli}->{fullhelo}\r\n",0); # send the ehlo again
        mlog($ssl,"info: sent EHLO again to $serIP") if ($ConnectionLog >=2);
        $Con{$ssl}->{getline}=\&replyTLS2;
    } else {  # STARTTLS rejected
    # process TLSqueue on client
        mlog($fh,"info: injected STARTTLS request rejected by $serIP") if $ConnectionLog >= 2;
        &getline($cli,"$ffr\r\n");
        delete $Con{$cli}->{TLSqueue};
        $Con{$fh}->{getline}=\&reply;
    }
}
