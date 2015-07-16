#line 1 "sub main::BlockReport"
package main; sub BlockReport {
    my ( $fh, $l ) = @_;
    my $this = $Con{$fh};
    if ( $l =~ /^ *DATA/io || $l =~ /^ *BDAT (\d+)/io ) {
        if ($1) {
            $this->{bdata} = $1;
        } else {
            delete $this->{bdata};
        }
        $this->{getline} = \&BlockReportBody2Q;
        my $report = 'blocked email report';
        sendque( $fh, "354 OK Send $report body\r\n" );
        $this->{lastcmd} = 'DATA';
        push( @{ $this->{cmdlist} }, $this->{lastcmd} ) if $ConnectionLog >= 2;
        return;
    } elsif ( $l =~ /^ *RSET/io ) {
        stateReset($fh);
        $this->{getline} = \&getline;
        sendque( $this->{friend}, "RSET\r\n" );
        $this->{lastcmd} = 'RSET';
        push( @{ $this->{cmdlist} }, $this->{lastcmd} ) if $ConnectionLog >= 2;
        return;
    } elsif ( $l =~ /^ *QUIT/io ) {
        stateReset($fh);
        $this->{getline} = \&getline;
        sendque( $this->{friend}, "QUIT\r\n" );
        $this->{lastcmd} = 'QUIT';
        push( @{ $this->{cmdlist} }, $this->{lastcmd} ) if $ConnectionLog >= 2;
        return;
    } elsif ( $l =~ /^ *XEXCH50 +(\d+)/io ) {
        d("XEXCH50 b=$1");
        sendque( $fh, "504 Need to authenticate first\r\n" );
        $this->{lastcmd} = 'XEXCH50';
        push( @{ $this->{cmdlist} }, $this->{lastcmd} ) if $ConnectionLog >= 2;
        return;
    }
    sendque( $fh, "250 OK\r\n" );
}
