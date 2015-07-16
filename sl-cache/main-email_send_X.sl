#line 1 "sub main::email_send_X"
package main; sub email_send_X {
    my ($class, $message, @args) = @_;

    my %args;
    if ( @args % 2 ) {
        my $host = shift @args;
        %args = @args;
        $args{Host} = $host;
    } else {
        %args = @args;
    }

    my $host = delete($args{Host}) || 'localhost';

    my $smtp_class = $args{ssl} ? 'Net::SMTP::SSL' : 'Net::SMTP';

    my $tls = ($args{tls} & ! $args{ssl} & ! $args{NoTLS}) ? ' (will try STARTTLS)' : '';
    delete $args{tls};
    delete $args{ssl};
    delete $args{NoTLS};
    $args{LocalAddr} ||= &main::getLocalAddress('SMTP',$host) unless exists $args{LocalAddr};
    delete $args{LocalAddr} unless $args{LocalAddr};

    if ($smtp_class eq 'Net::SMTP::SSL') {
        my %parms = getSSLParms(0);
        $parms{SSL_startHandshake} = 1;
        $args{sslParms} = \%parms;
    }
    mlog(0,"info: $smtp_class is used to send mail$tls") if $ConnectionLog > 1;
    my $SMTP = $smtp_class->new($host, %args);
    if (! $SMTP) {
        mlog(0,"Couldn't connect to $host");
        return 0;
    }

    ${*$SMTP}{'net_smtp_port'} = $args{Port};
    ${*$SMTP}{'net_smtp_helo'} = $args{Helo};

    if ($tls) {
        if (! eval{$SMTP->starttls();}) {
            mlog(0,"Couldn't start TLS: $@");
            return 0;
        }
    }
    
    my ($user, $pass) = @args{qw[username password]};

    if ( $user && $pass) {
        my $r;
        eval{$r = $SMTP->auth($user, $pass);};
        if ($@) {
            mlog(0,"Couldn't authenticate '$user' - $@");
            return 0;
        }
        if ($r == 0) {
            mlog(0,"authentication failed for '$user:...'");
            return 0;
        }
    }

    my @bad;
    eval {
        my $from = $args{From} || $args{from} || $class->get_env_sender($message);

        # ::TLS has no useful return value, but will croak on failure.
        if (! eval { $SMTP->mail($from); } ) {
            die("FROM: <$from> denied\n");
        }
        my $to = $args{To} || $args{to};
        my @to = (ref($to) ? @{$to} : $to) || $class->get_env_recipients($message);
        if (@to) {
            my @ok = $SMTP->to(@to, { SkipBad => 1 });

            if ( @to != @ok ) {
                my %to; @to{@to} = (1) x @to;
                delete @to{@ok};
                @bad = keys %to;
            }
        }

        if (@bad == @to) {
            die("No valid recipients found in '@to'\n");
        }
    };

    if ($@) {
        mlog(0,"error: email_send failed - $@");
        return 0;
    }

    my $timeout = (int(length($message) / (1024 * 1024)) + 1) * 60; # 1MB/min
    eval {
        $SMTP->data();
        my $blocking = $SMTP->blocking(0);
        NoLoopSyswrite($SMTP, $message->as_string . "\r\n", $timeout) or die "$!\n";
        $SMTP->blocking($blocking);
        $SMTP->dataend();
        1;
    } or do {
        mlog(0,"Can't send data - $@");
        return 0;
    };
    eval {$SMTP->quit;1;} or do {mlog(0,"Can't QUIT SMTP session - $@");return 0;};
    mlog(0,'Message sent - not accepted recipients: ' . join(', ',@bad)) if @bad;
    return 1;
}
