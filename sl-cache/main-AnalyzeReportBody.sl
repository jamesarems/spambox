#line 1 "sub main::AnalyzeReportBody"
package main; sub AnalyzeReportBody {
    my ( $fh, $l ) = @_;
    my $this = $Con{$fh};
    my $sub;
    d('AnalyzeReportBody');

    $this->{header} .= $l;
    if ( $l =~ /^\.[\r\n]/o || defined( $this->{bdata} ) && $this->{bdata} <= 0 ) {

        my $email = ReportBodyUnZip($fh);
        # we're done -- write the file & clean up
        # are there attached messages ? - process them
        if ($CanUseEMM && $maillogExt && $email) {
            my $name;
            eval {
                $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
                $email ||= Email::MIME->new($this->{header});
                fixUpMIMEHeader($email);
                my @parts = parts_subparts($email);
                foreach my $part ( @parts ) {
                    my $name =   attrHeader($part,'Content-Type','name','filename')
                              || $part->filename
                              || attrHeader($part,'Content-Disposition','name','filename');
                    if ($part->header("Content-Disposition")=~ /attachment|inline/io && $name =~ /\Q$maillogExt\E$/i) {
                        my $body = $part->body;
                        $body =~ s/\.(?:\r?\n)+$//o;
                        $body = "dummy header to remove\r\n\r\n" . $body;
                        while (my ($k,$v) = each %{$Con{$fh}}) {
                            $Con{$part}->{$k} = $v;
                        }
                        $Con{$part}->{reporthint} = "analyzed attached message file : '$name'";
                        $Con{$part}->{header} = ($MaxBytesReports) ? substr($body,0,$MaxBytesReports) : $body;
                        delete $Con{$part}->{report};
                        $this->{report} .= "\n\n\n\n\n\n" if $this->{report};
                        $sub = AnalyzeText( $part );
                        mlog(0,"Analyze Report: processed attached messagefile $name from $this->{mailfrom}")  if $ReportLog >= 2;
                        eval {
                            $name = e8($name);
                            1;
                        } or do {$name = "[$@]"; $name =~ s/\r?\n/ /go;};
                        $this->{report} .= $Con{$part}->{report};
                        delete $Con{$part};
                    } elsif ($part->header("Content-Disposition")=~ /attachment|inline/io && $name && $name !~ /\Q$maillogExt\E$/i) {
                        mlog(0,"Analyze Report: got unexpected attachment $name from $this->{mailfrom} - missing extension '$maillogExt'")  if $ReportLog;
                    }
                }
                1;
            } or do {mlog(0,"error: analyze - decoding failed - attachment $name ignored - $@");};
        }

        unless ($this->{report}) {
            $this->{header} = substr($this->{header},0,$MaxBytesReports) if $MaxBytesReports;
            $this->{header} =~ s/\.(?:\r?\n)+$//o;
            $sub = AnalyzeText( $fh );
        }

        # mail analyze report
        ReturnMail($fh, $this->{mailfrom}, "$base/$ReportFiles{EmailAnalyze}", $sub, \"$this->{rcpt}\n\n$this->{report}\n" )
          if ( $EmailAnalyzeReply == 1 || $EmailAnalyzeReply == 3 );

        $this->{isadmin} = 1;
        ReturnMail(
            $fh,
            $EmailAnalyzeTo, "$base/$ReportFiles{EmailAnalyze}",
            $sub, \"$this->{rcpt}\n\n$this->{report}\n",
            $this->{mailfrom}
          ) if ( $EmailAnalyzeTo && ( $EmailAnalyzeReply == 2 || $EmailAnalyzeReply == 3 ) );
        delete $this->{isadmin};
        
        delete $this->{report};
        stateReset($fh);
        $this->{getline} = \&getline;
        sendque( $this->{friend}, "RSET\r\n" );

    }
}
