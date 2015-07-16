#line 1 "sub main::DMARCSendForensic"
package main; sub DMARCSendForensic {
    my $fh = shift;
    my $this = $Con{$fh};
    my $report_id = Time::HiRes::time;
    my $size = $this->{dmarc}->{rufSize} || 0;
    my ($rcvdtime) = $this->{rcvd} =~ /;\s*([^;]+)\r\n$/os;
    my $dkimident;
    if (@{$this->{dmarc}->{DKIMdomains}}) {
        $dkimident = $this->{dmarc}->{dom} if grep(/^\Q$this->{dmarc}->{dom}\E$/,@{$this->{dmarc}->{DKIMdomains}});
    }
    $dkimident ||= 'none';
    my $mailFrom = $DMARCReportFrom;
    $mailFrom .= "\@$this->{dmarc}->{toDomain}" if $mailFrom !~ /\@/o;
    my $mail = <<EOT;
This is a spf/dkim forensic authentication-failure report for an email message received from IP $this->{dmarc}->{source_ip} on $rcvdtime.
Below is some detail information about this message:
 1. SPF-authenticated Identifiers: $this->{dmarc}->{mfd};
 2. SPF Mechanism Check Result: $this->{dmarc}->{auth_results}->{spf};
 3. DKIM-authenticated Identifiers: $dkimident;
 4. DMARC Mechanism Check Result: DMARC mechanism check $this->{dmarc}->{auth_results}->{dkim};

For more information please check Aggregate Reports or mail to $mailFrom .
Feedback-Type: auth-failure
User-Agent: ASSP/$version
Version: $MAINVERSION
Original-Mail-From: <$this->{mailfrom}>
Arrival-Date: $rcvdtime
Source-IP: $this->{dmarc}->{source_ip}
Reported-Domain: $this->{dmarc}->{toDomain}
Authentication-Results: $this->{dmarc}->{dom}; spf=$this->{dmarc}->{auth_results}->{spf} smtp.mailfrom=$this->{mailfrom}; dkim=$this->{dmarc}->{auth_results}->{dkim}
Delivery-Result: reject
EOT
    $mail =~ s/\r?\n/\r\n/go;
    $mail .= "\r\n\r\n" . $this->{header};
    my $filename = 'f' . Time::HiRes::time;
    my $msgid = "<$filename\@$myName>";
    if ($SPFLog >= 2 || $DebugSPF) {
        my $rfile = "$base/debug/dmarc_$filename".'.txt';
        if ($open->(my $f,">",$rfile)) {
            $f->binmode;
            $f->print($mail);
            $f->close;
            mlog(0,"info: DMARC-Forensic report stored in $rfile") if $MaintenanceLog;
        } else {
            mlog(0,"error: unable to write DMARC-Forensic report to file $rfile - $!");
        }
    }
    if ($size && length($mail) > $size) {
        mlog(0,'info: skip DMARC forensic report for domain $this->{dmarc}->{dom} - report size is larger than policy restriction '.formatNumDataSize($size)) if $MaintenanceLog;
        return;
    }

    my @parts = (
        Email::MIME->create(
            attributes => {
                content_type => 'text/plain',
                encoding     => '7bit',
                charset      => 'US-ASCII',
            },
            body_str => $mail,
        )
    );
    my $email = Email::MIME->create(
        header_str => [ From => $mailFrom,
                        To => $this->{dmarc}->{ruf},
                        Subject => "Report Domain: $this->{dmarc}->{domain} Submitter: $this->{dmarc}->{toDomain} Report-ID: <$report_id>",
                        'Message-ID' => $msgid
                      ],
        parts      => [ @parts ],
    );
    my $rfile = "$base/$resendmail/dmarc_$filename$maillogExt";
    if ($open->(my $f,">",$rfile)) {
        $f->binmode;
        $f->print($email->as_string);
        $f->close;
        mlog(0,"info: DMARC forensic report message queued to sent to $this->{dmarc}->{ruf}") if $MaintenanceLog;
        $nextResendMail = $nextResendMail < time + 3 ? $nextResendMail : time + 3;
    } else {
        mlog(0,"error: unable to write DMARC forensic report message to file $rfile - $!");
    }
    return;
}
