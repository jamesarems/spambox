#line 1 "sub main::ListReport"
package main; sub ListReport {
    my($fh,$l)=@_;
    d('ListReport');
    my $this=$Con{$fh};
	my $tmp = $l ;
	$tmp =~ s/\r|\n|\s//igo;
	$tmp =~ /^([a-zA-Z0-9]+)/o;
	if ($1) {
	    $this->{lastcmd} = substr($1,0,14);
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
    }
    if( $l=~/^ *DATA/io || $l=~/^ *BDAT (\d+)/io ) {
        if($1) {
            $this->{bdata}=$1;
        } else {
            delete $this->{bdata};
        }
        sendque($this->{friend},"RSET\r\n"); # make sure to reset the pending email
        $this->{getline}=\&ListReportBody;
        my $list;
        if ($ReportTypes{$this->{reportaddr}} < 6) {
            $list=(($ReportTypes{$this->{reportaddr}} & 4)==0) ? "whitelist" : "redlist" if !$EmailErrorsModifyWhite;
            $list= "spam" if $EmailErrorsModifyWhite && $this->{reportaddr} eq 'EmailSpam';
            $list= "ham" if $EmailErrorsModifyWhite && $this->{reportaddr} eq 'EmailHam';
        }
        sendque($fh,"354 OK Send $list body\r\n");
        return;
    } elsif( $l=~/^ *RSET/io ) {
        stateReset($fh);
        $this->{getline}=\&getline;
        sendque($this->{friend},"RSET\r\n");
        return;
    } elsif( $l=~/^ *QUIT/io ) {
        stateReset($fh);
        $this->{getline}=\&getline;
        sendque($this->{friend},"QUIT\r\n");
        return;
    } elsif( $l=~/^ *XEXCH50 +(\d+)/io ) {
        d("XEXCH50 b=$1");
        sendque($fh,"504 Need to authenticate first\r\n");
        return;
    } else {

        # more recipients ?
        while ($l=~/($EmailAdrRe\@$EmailDomainRe)/og) {
            next if $1 eq $this->{mailfrom};
            $this->{rcpt}.="$1 ";
            ListReportExec($1,$this);
        }

    }
    sendque($fh,"250 OK\r\n");
}
