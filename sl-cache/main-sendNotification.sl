#line 1 "sub main::sendNotification"
package main; sub sendNotification {
    my ($from,$to,$sub,$body,$file) = @_;
    my $text;
    if (! $from) {
        $from = 'ASSP <>';
        mlog(0,"*x*warning: 'EmailFrom' seems to be not configured - using '$from' as FROM: address");
    }
    if (! $to) {
        mlog(0,"*x*warning: TO: address not found for notification email - abort");
        return;
    }
    if (! $resendmail) {
        mlog(0,"*x*warning: 'resendmail' is not configured - abort notification");
        return;
    }
    my $date=$UseLocalTime ? localtime() : gmtime();
    my $tz=$UseLocalTime ? tzStr() : '+0000';
    $date=~s/(\w+) +(\w+) +(\d+) +(\S+) +(\d+)/$1, $3 $2 $5 $4/o;
    $text = "Date: $date $tz\r\n";
    $text .= "X-Assp-Notification: YES\r\n";
    $from =~ s/^\s+//o;
    $from =~ s/\s+$//o;
    if ($from !~ /\</o) {
        $text .= "From: <$from>\r\nTo:";
    } else {
        my ($t,$m) = split(/</o, $from);
        $m = '<' . $m;
        $t =~ s/^\s+//o;
        $t =~ s/\s+$//o;
        $t = encodeMimeWord($t,'Q','UTF-8') . ' ' if $t;
        $text .= "From: $t$m\r\nTo:";
    }
    foreach (split(/,|\|/o, $to)) {
        s/^\s+//o;
        s/\s+$//o;
        if ($_ !~ /\</o) {
            $text .= " <$_>,";
        } else {
            my ($t,$m) = split(/</o, $_);
            $m = '<' . $m;
            $t =~ s/^\s+//o;
            $t =~ s/\s+$//o;
            $t = encodeMimeWord($t,'B','UTF-8') . ' ' if $t;
            $text .= " $t$m,";
        }
    }
    chop $text;
    $text .= "\r\n";
    $sub = encodeMimeWord($sub,'B','UTF-8');
    $text .= "Subject: $sub\r\n";
    $text .= "MIME-Version: 1.0\r\n";
    $text .= "Content-Type: text/plain; charset=\"UTF-8\"\r\n";
    $text .= "Content-Transfer-Encoding: quoted-printable\r\n";
    my $msgid = $WorkerNumber . sprintf("%06d",$NotifyCount++) . int(rand(100));
    $text .= "Message-ID: a$msgid\@$myName\r\n";
    $text = headerWrap($text);
    $text .= "\r\n";           # end header
    my $sendbody;
    foreach (split(/\r?\n/o,$body)) {
        $sendbody .= ( $_ ? assp_encode_Q(e8($_)) : '') . "\r\n";
    }
    my $f;
    if ($file && $open->($f,"<",$file)) {
        while (<$f>) {
             s/\r?\n$//o;
             $sendbody .= ( $_ ? assp_encode_Q(e8($_)) : '') . "\r\n";
        }
        $f->close;
    }
    $text .= $sendbody;
    $f = undef;
    my $rfile = "$base/$resendmail/n$msgid$maillogExt";
    if ($open->($f,">",$rfile)) {
        $f->binmode;
        $f->print($text);
        $f->close;
        mlog(0,"*x*info: notification message queued to sent to $to") if $MaintenanceLog;
        $nextResendMail = $nextResendMail < time + 3 ? $nextResendMail : time + 3;
    } else {
        mlog(0,"*x*error: unable to write notify message to file $file - $!");
    }
}
