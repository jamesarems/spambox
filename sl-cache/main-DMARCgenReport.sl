#line 1 "sub main::DMARCgenReport"
package main; sub DMARCgenReport {
    my $force = shift;
    my $polcount = scalar keys %DMARCpol;
    mlog(0,"DMARCpol: searching for DMARC-agregate-reports to generate in $polcount stored DMARC policy records") if $MaintenanceLog >= 2;
    my @deletePol;
    while (my($k,$v) = each %DMARCpol) {
        my $re = quotemeta($k);
        my ($st,$ri,$to,$size);
        ($st,$ri,$to,$size) = ($1,$2,$3,$4) if $v =~ s/^(\d+) (\d+) (\S+) (\d+) //o;
        if (! $st || ! $ri || ! $to) {
            push @deletePol, $k;
            my @deleteRec;
            while (my ($r,$c) = each %DMARCrec) {
                my $or = $r;
                next unless $r =~ s/^$re\r?\n//s;
                mlog(0,"info: removed DMARC rua record: $r") if $MaintenanceLog >= 2;
                push @deleteRec, $or;
            }
            map {delete $DMARCrec{$_};} @deleteRec;
            next;
        }
        next if (time < $ri && ! $force);
        my ($domain,$toDomain) = split(/ /o,$k);
        my $mailFrom = $DMARCReportFrom;
        $mailFrom .= "\@$toDomain" if $mailFrom !~ /\@/o;
        my $report_id = Time::HiRes::time;
        my $begin = $st + TimeZoneDiff();
        my $end = ($force ? time + TimeZoneDiff() : $ri + TimeZoneDiff());
        my $mail = <<EOT;
<feedback>
 <report_metadata>
  <org_name>$toDomain</org_name>
  <email>$mailFrom</email>
  <report_id>$report_id</report_id>
  <date_range>
   <begin>$begin</begin>
   <end>$end</end>
  </date_range>
 </report_metadata>
EOT
        $mail .= $v;
        my @deleteRec;
        while (my ($r,$c) = each %DMARCrec) {
            my $or = $r;
            next unless $r =~ s/^$re\r?\n//s;
            $r =~ s/XxxCOUNTyyY/<count>$c<\/count>/os;
            mlog(0,"info: add DMARC rua record: $r") if $MaintenanceLog >= 2;
            $mail .= $r;
            push @deleteRec, $or;
        }
        map {delete $DMARCrec{$_};} @deleteRec;
        $mail .= "</feedback>\n";
        my $filename = 'a' . Time::HiRes::time;
        my $msgid = "<$filename\@$myName>";
        if ($SPFLog >= 2 || $DebugSPF) {
            my $rfile = "$base/debug/dmarc_$filename".'.xml';
            if ($open->(my $f,">",$rfile)) {
                $f->binmode;
                $f->print($mail);
                $f->close;
                mlog(0,"info: DMARC-XML report stored in $rfile") if $MaintenanceLog;
            } else {
                mlog(0,"error: unable to write DMARC-XML report to file $rfile - $!");
            }
        }
        push @deletePol, $k;
        eval{require IO::Compress::Zip; 1;} or next;
        my $zmail;
        IO::Compress::Zip::zip(\$mail => \$zmail, Name => "$toDomain!$domain!$begin!$end.xml") or next;
        undef $mail;
        if ($size && length($zmail) > $size) {
            mlog(0,'info: skip DMARC report for domain $domain - report size is larger than policy restriction '.formatNumDataSize($size)) if $MaintenanceLog;
            next;
        }
        # multipart message - attach DMARC report as ZIP
        my @parts = (
            Email::MIME->create(
                attributes => {
                    disposition  => 'attachment',
                    filename     => "$toDomain!$domain!$begin!$end.zip",
                    content_type => 'application/x-zip-compressed',
                    encoding     => 'base64',
                    name         => "$toDomain!$domain!$begin!$end.zip",
                },
                body => $zmail,
            ),
            Email::MIME->create(
                attributes => {
                    content_type => 'text/plain',
                    encoding     => '7bit',
                    charset      => 'US-ASCII',
                },
                body_str => "This is an aggregate report from $toDomain .",
            ),
        );
        my $email = Email::MIME->create(
            header_str => [ From => $mailFrom,
                            To => $to,
                            Subject => "Report Domain: $domain Submitter: $toDomain Report-ID: <$report_id>",
                            'Message-ID' => $msgid
                          ],
            parts      => [ @parts ],
        );
        my $rfile = "$base/$resendmail/dmarc_$filename$maillogExt";
        if ($open->(my $f,">",$rfile)) {
            $f->binmode;
            $f->print($email->as_string);
            $f->close;
            mlog(0,"info: DMARC report message queued to sent to $to") if $MaintenanceLog;
            $nextResendMail = $nextResendMail < time + 3 ? $nextResendMail : time + 3;
        } else {
            mlog(0,"error: unable to write DMARC report message to file $rfile - $!");
        }

        if ($SPFLog >= 2 || $DebugSPF) {
            $rfile = "$base/debug/dmarc_$filename$maillogExt";
            if ($open->(my $f,">",$rfile)) {
                $f->binmode;
                $f->print($email->as_string);
                $f->close;
                mlog(0,"info: DMARC report message stored in $rfile") if $MaintenanceLog;
            } else {
                mlog(0,"error: unable to write DMARC report message to file $rfile - $!");
            }
        }
    }
    map {delete $DMARCpol{$_};} @deletePol;
    return;
}
