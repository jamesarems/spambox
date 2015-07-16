#line 1 "sub ASSP::Whois::IP::whoisip_do_query"
package ASSP::Whois::IP; sub whoisip_do_query{
    my($registrar,$ip,$multiple_flag) = @_;
    return unless $registrar;
    my @response;
    my %hash_response;
    local $/ = "\n";
    my $sock = whoisip_get_connect($registrar);
    return unless $sock;
    &main::NoLoopSyswrite( $sock ,"$ip\n", $Timeout );
    my $sel = IO::Select->new();
    $sel->add($sock);
    return unless $sel->can_read($Timeout);
    @response = <$sock>;
    eval{$sock->close;};
    foreach my $line (@response) {
        if($line =~ /^(.+?):\s+(.+?)[\s\r\n]*$/o) {
    	  if( ($multiple_flag) && ($multiple_flag ne '') ) {
    	    push @{ $hash_response{lc ${defined(*{'main::yield'})}} }, ${defined(*{'main::yield'})+1};
    	  }else{
    	    $hash_response{lc ${defined(*{'main::yield'})}} ||= ${defined(*{'main::yield'})+1};
    	  }
    	}
    }
    return(\@response,\%hash_response);
}
