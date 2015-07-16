#line 1 "sub main::ListReportBody"
package main; sub ListReportBody {
    my($fh,$l)=@_;
    my $this=$Con{$fh};
    my $sub;
    my %addresses;
    d('ListReportBody');
    
    my $MaxBytesReports = $MaxBytesReports;
    $MaxBytesReports ||= 1024000;
    $this->{header} .= $l if length($this->{header}) < $MaxBytesReports;
    if($l=~/^\.[\r\n]/o || defined($this->{bdata}) && $this->{bdata}<=0) {

        $this->{header} =~ s/\x0D?\x0A/\x0D\x0A/go;
        $this->{header} =~ s/^(?:\x0D\x0A)+//o;

        if ($EmailForwardReportedTo && ($this->{reportaddr} eq 'EmailSpam' || $this->{reportaddr} eq 'EmailHam')) {
            if (defined${chr(ord(",")<< 1)} && &forwardHamSpamReport($fh)) {
                stateReset($fh);
                $this->{getline}=\&getline;
                sendque($fh,"250 OK\r\n");
                sendque($this->{friend},"RSET\r\n");
                return;
            } else {
                mlog(0,"warning: unable to forward the report request to any of '$EmailForwardReportedTo' - will process the request locally!");
            }
        }
        
        for my $addr (&ListReportGetAddr($fh)) {   # process the addresses
            next if exists $addresses{lc $addr};
            $addresses{lc $addr} = 1;
            &ListReportExec($addr,$this);
        }
        if (! scalar keys %addresses && ($this->{reportaddr} eq 'EmailPersBlackAdd' or $this->{reportaddr} eq 'EmailPersBlackRemove')) {
            &ListReportExec('reportpersblack@anydom.com',$this);
        }

        $this->{header} = substr($this->{header},0,$MaxBytesReports) if $MaxBytesReports;
        # we're done -- write the file & clean up

        my $file = "$base/" . ( exists $ReportFiles{$this->{reportaddr}}
                 ? $ReportFiles{$this->{reportaddr}}
                 : $ReportFiles{'EmailHelp'} );

        ListReportExec( $this->{mailfrom}, $this ) if (! exists $addresses{lc $this->{mailfrom}} && ($ReportTypes{$this->{reportaddr}}>=10 || $this->{reportaddr} eq 'EmailRedlistRemove' || $this->{reportaddr} eq 'EmailRedlistAdd'));

        # mail summary report
        if ($this->{reportaddr} eq 'EmailWhitelistRemove' || $this->{reportaddr} eq 'EmailWhitelistAdd') {
            ReturnMail($fh,$this->{mailfrom},$file,'',\"$this->{rcpt}\n\n$this->{report}\n") if ($EmailWhitelistReply==1 || $EmailWhitelistReply==3);
            $this->{isadmin} = 1;
            ReturnMail($fh,$EmailWhitelistTo,$file,'',\"$this->{rcpt}\n\n$this->{report}\n",$this->{mailfrom}) if ( $EmailWhitelistTo && ($EmailWhitelistReply==2 || $EmailWhitelistReply==3));
        } elsif  ($this->{reportaddr} eq 'EmailHelp' )
        {
            ReturnMail($fh,$this->{mailfrom},$file,'ASSP-Help', \"$this->{rcpt}\n\n$this->{report}\n") ;

        } elsif  ($this->{reportaddr} eq 'EmailRedlistAdd' || $this->{reportaddr} eq 'EmailRedlistRemove')
        {
            ReturnMail($fh,$this->{mailfrom},$file,'',\"$this->{rcpt}\n\n$this->{report}\n") if ($EmailRedlistReply==1 || $EmailRedlistReply==3);
            $this->{isadmin} = 1;
            ReturnMail($fh,$EmailRedlistTo,$file,'',\"$this->{rcpt}\n\n$this->{report}\n",$this->{mailfrom}) if ( $EmailRedlistTo && ($EmailRedlistReply==2 || $EmailRedlistReply==3));
        } elsif  ($this->{reportaddr} eq 'EmailSpamLoverAdd' || $this->{reportaddr} eq 'EmailSpamLoverRemove')
        {
            ReturnMail($fh,$this->{mailfrom},$file,$sub,\"$this->{rcpt}\n\n$this->{report}\n") if ($EmailSpamLoverReply==1 || $EmailSpamLoverReply==3);
            $this->{isadmin} = 1;
            ReturnMail($fh,$EmailSpamLoverTo,$file,$sub,\"$this->{rcpt}\n\n$this->{report}\n",$this->{mailfrom}) if ($EmailSpamLoverTo && ($EmailSpamLoverReply==2 || $EmailSpamLoverReply==3));
        } elsif ( $this->{reportaddr} eq 'EmailBlackAdd' || $this->{reportaddr} eq 'EmailBlackRemove' || $this->{reportaddr} eq 'EmailPersBlackAdd' || $this->{reportaddr} eq 'EmailPersBlackRemove')
        {
            ReturnMail($fh, $this->{mailfrom},$file, $sub,\"$this->{rcpt}\n\n$this->{report}\n" ) if ( $EmailBlackReply == 1 || $EmailBlackReply == 3 );
            $this->{isadmin} = 1;
            ReturnMail($fh, $EmailBlackTo, $file, $sub,\"$this->{rcpt}\n\n$this->{report}\n",$this->{mailfrom}) if ( $EmailBlackTo && ( $EmailBlackReply == 2 || $EmailBlackReply == 3 ) );
        } elsif  ($this->{reportaddr} eq 'EmailNoProcessingAdd' || $this->{reportaddr} eq 'EmailNoProcessingRemove')
        {
            ReturnMail($fh,$this->{mailfrom},$file,$sub,\"$this->{rcpt}\n\n$this->{report}\n") if ($EmailNoProcessingReply==1 || $EmailNoProcessingReply==3);
            $this->{isadmin} = 1;
            ReturnMail($fh,$EmailNoProcessingTo,$file,$sub,\"$this->{rcpt}\n\n$this->{report}\n",$this->{mailfrom}) if ($EmailNoProcessingTo && ($EmailNoProcessingReply==2 || $EmailNoProcessingReply==3));
        }
        delete $this->{isadmin};
        delete $this->{report};
        stateReset($fh);
        $this->{getline}=\&getline;
        sendque($fh,"250 OK\r\n");
        sendque($this->{friend},"RSET\r\n");
    }
}
