#line 1 "sub main::SpamReportBody"
package main; sub SpamReportBody {
    my ($fh, $l)=@_;
    d('SpamReportBody');
    my $this=$Con{$fh};
    my $MaxBytesReports = $MaxBytesReports;
    $MaxBytesReports ||= 1024000;
    $this->{header}.=$l if length($this->{header}) < $MaxBytesReports;
    my $sub;
    my $type;
    my %addresses;
    my $numparts = 0;
    if($l=~/^\.[\r\n]/o || defined($this->{bdata}) && $this->{bdata}<=0) {

        # we're done -- write the file & clean up
        $type = $this->{reportaddr} eq 'EmailSpam' ? 'Spam' : 'Ham';
        if (! $this->{mailfrom} && $this->{header} =~ /X-Assp-Intended-For:\s*($EmailAdrRe\@$EmailDomainRe)/io) {
            $this->{noreportTo} = $this->{mailfrom} = $1;
            mlog(0,"$type-Report: empty sender is replaced by 'X-Assp-Intended-For' $this->{mailfrom} - no reports will be sent") if $ReportLog;
        }
        my $msg = ($MaxBytesReports) ? substr($this->{header},0,$MaxBytesReports) : $this->{header};
        mlog(0,"$type-Report: process message from $this->{mailfrom}") if $ReportLog;
        # are there attached messages ? - process them
        my $email = ReportBodyUnZip($fh);
        if ($CanUseEMM && $maillogExt && $email) {
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
                        $numparts++;
                        d("SpamReportBody - processing attached email $name");
                        mlog(0,"$type-Report: processing attached messagefile ($numparts) $name") if $ReportLog;
                        my $dfh = "$fh" . "_X$numparts";
                        $Con{$dfh}->{mailfrom} = $this->{mailfrom};
                        $Con{$dfh}->{reportaddr} = $this->{reportaddr};
                        my $body = $part->body;

                        if ( $EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP == 1) {
                            $Con{$dfh}->{header} = "\r\n\r\n".$body;
                            for my $addr (&ListReportGetAddr($dfh)) {   # process the addresses
                                next if exists $addresses{lc $addr};
                                $addresses{lc $addr} = 1;
                                &ListReportExec($addr,$Con{$dfh});
                            }
                            $Con{$dfh}->{header} =~ s{^\r\n\r\n}{}o;
                        }

                        if ( scalar keys %addresses && matchSL( $Con{$dfh}->{mailfrom}, 'EmailErrorsModifyPersBlack' ) ) {
                            $Con{$dfh}->{header} = "\r\n\r\n".$body;
                            my $reportaddr = $Con{$dfh}->{reportaddr};
                            $Con{$dfh}->{reportaddr} = 'EmailPersBlackAdd' if $Con{$dfh}->{reportaddr} eq 'EmailSpam';
                            $Con{$dfh}->{reportaddr} = 'EmailPersBlackRemove' if $Con{$dfh}->{reportaddr} eq 'EmailHam';
                            my %seen;
                            for my $addr (&ListReportGetAddr($dfh)) {
                                next if exists $seen{lc $addr};
                                $seen{lc $addr} = 1;
                                &ListReportExec($addr,$Con{$dfh});
                            }
                            $Con{$dfh}->{reportaddr} = $reportaddr;
                            $Con{$dfh}->{header} =~ s{^\r\n\r\n}{}o;
                        }
                        
                        if ($DoAdditionalAnalyze) {
                            my $currReport = $Con{$dfh}->{report};
                            $Con{$dfh}->{report} = '';

                            my $reportaddr = $Con{$dfh}->{reportaddr};
                            $Con{$dfh}->{reportaddr} = 'EmailAnalyze';

                            $Con{$dfh}->{header} = "\r\n\r\n".$body;
                            $Con{$dfh}->{classification} = ($type eq 'Spam') ? 'SPAM report' : 'NOT-SPAM report';
                            my $sub=AnalyzeText($dfh);

                            # mail analyze report
                            ReturnMail($dfh,$this->{mailfrom},"$base/$ReportFiles{EmailAnalyze}",$sub, \"\n$Con{$dfh}->{report}\n") if ($DoAdditionalAnalyze==1 || $DoAdditionalAnalyze==3);
                            $Con{$dfh}->{isadmin} = 1;
                            ReturnMail($dfh,$EmailAnalyzeTo,"$base/$ReportFiles{EmailAnalyze}",$sub, \"\n$Con{$dfh}->{report}\n", $this->{mailfrom}) if ( $EmailAnalyzeTo && ($DoAdditionalAnalyze==2 || $DoAdditionalAnalyze==3));
                            delete $Con{$dfh}->{isadmin};
                            
                            $Con{$dfh}->{reportaddr} = $reportaddr;
                            $Con{$dfh}->{report} = $currReport;
                        }

                        my $ssub = SpamReportExec($body,(($type eq 'Spam') ? $correctedspam : $correctednotspam),$this->{mailfrom});
                        $sub = $ssub if $numparts == 1;
                        mlog(0,"$type Report: processed attached messagefile $name from $this->{mailfrom}")  if $ReportLog >= 2;
                        $this->{report} .= "\r\n\r\n".$Con{$dfh}->{report} if $Con{$dfh}->{report};
                        delete $Con{$dfh};
                    }
                }
            };
        }
        if ($numparts == 0) {
            mlog(0,"$type-Report: (no attachment) - processing raw email") if $ReportLog > 1;
            if ( $EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP == 1) {
                for my $addr (&ListReportGetAddr($fh)) {   # process the addresses
                    next if exists $addresses{lc $addr};
                    $addresses{lc $addr} = 1;
                    &ListReportExec($addr,$this);
                }
            }
            if ( scalar keys %addresses && matchSL( $this->{mailfrom}, 'EmailErrorsModifyPersBlack' ) ) {
                my $reportaddr = $this->{reportaddr};
                $this->{reportaddr} = 'EmailPersBlackAdd' if $this->{reportaddr} eq 'EmailSpam';
                $this->{reportaddr} = 'EmailPersBlackRemove' if $this->{reportaddr} eq 'EmailHam';
                my %seen;
                for my $addr (&ListReportGetAddr($fh)) {
                    next if exists $seen{lc $addr};
                    $seen{lc $addr} = 1;
                    &ListReportExec($addr,$this);
                }
                $this->{reportaddr} = $reportaddr;
            }
            if ($DoAdditionalAnalyze) {
                my $currReport = $this->{report};
                $this->{report} = '';
                
                my $reportaddr = $this->{reportaddr};
                $this->{reportaddr} = 'EmailAnalyze';

                my $sub=AnalyzeText($fh);

                # mail analyze report
                ReturnMail($fh,$this->{mailfrom},"$base/$ReportFiles{EmailAnalyze}",$sub, \"\n$this->{report}\n") if ($DoAdditionalAnalyze==1 || $DoAdditionalAnalyze==3);
                $this->{isadmin} = 1;
                ReturnMail($fh,$EmailAnalyzeTo,"$base/$ReportFiles{EmailAnalyze}",$sub, \"\n$this->{report}\n", $this->{mailfrom}) if ( $EmailAnalyzeTo && ($DoAdditionalAnalyze==2 || $DoAdditionalAnalyze==3));
                delete $this->{isadmin};
                
                $this->{report} = $currReport;
                $this->{reportaddr} = $reportaddr;
            }
            $sub=SpamReportExec($msg,(($this->{reportaddr} eq 'EmailSpam') ? $correctedspam : $correctednotspam),$this->{mailfrom});
        }
        mlog(0,"$type-Report: finished report-message from $this->{mailfrom}") if $ReportLog;
        $this->{header}='';

        ReturnMail($fh,$this->{mailfrom},"$base/$ReportFiles{$this->{reportaddr}}",$sub,\"$this->{rcpt}\n\n$this->{report}\n") if ($EmailErrorsReply==1 || $EmailErrorsReply==3);
        $this->{isadmin} = 1;
        ReturnMail($fh,$EmailErrorsTo,"$base/$ReportFiles{$this->{reportaddr}}",$sub,\"$this->{rcpt}\n\n$this->{report}\n",$this->{mailfrom}) if ($EmailErrorsTo && ($EmailErrorsReply==2 || $EmailErrorsReply==3));
        delete $this->{isadmin};
        
        stateReset($fh);
        $this->{getline}=\&getline;
        sendque($this->{friend},"RSET\r\n");
    }
}
