#line 1 "sub main::AnalyzeReport"
package main; sub AnalyzeReport {
    my($fh,$l)=@_;
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
        $this->{getline}=\&AnalyzeReportBody;

        sendque($fh,"354 OK Send analyze body\r\n");
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

    }
    sendque($fh,"250 OK\r\n");
}
