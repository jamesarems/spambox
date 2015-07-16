#line 1 "sub Net::SMTP::assp_starttls"
package Net::SMTP; sub assp_starttls {
	my $me = shift;
    return unless $me;
    return 1 if ${*$me}{'net_smtp_ssl'};
    if (! (exists ${*$me}{'net_smtp_esmtp'}->{STARTTLS} || exists ${*$me}{'net_smtp_esmtp'}->{TLS})) {
        &main::mlog(0,'info: host '.${*$me}{'net_smtp_host'}.':'.${*$me}{'net_smtp_port'}.' does not support STARTTLS') if ($main::MaintenanceLog > 1);
        return 1;
    }
    &main::mlog(0,'info: try STARTLS to host '.${*$me}{'net_smtp_host'}.':'.${*$me}{'net_smtp_port'}) if ($main::MaintenanceLog > 1);
    $me->command("STARTTLS");
	if($me->response() != eval('CMD_OK')) {
        $main::localTLSfailed{${*$me}{'net_smtp_host'}.':'.${*$me}{'net_smtp_port'}} = time;
        die "Invalid response for STARTTLS: ".$me->message."\n";
	}
    $IO::Socket::SSL::DEBUG = $main::SSLDEBUG;
    if(not IO::Socket::SSL->start_SSL($me,
                                      SSL_startHandshake => 1,
                                      &main::getSSLParms(0)))
    {
        $main::localTLSfailed{${*$me}{'net_smtp_host'}.':'.${*$me}{'net_smtp_port'}} = time;
        die $IO::Socket::SSL::errstr."\n";
	}
    push @IO::Socket::SSL::ISA, 'Net::SMTP' unless grep {$_ eq 'Net::SMTP'} @IO::Socket::SSL::ISA;
    ${*$me}{'net_smtp_ssl'} = 1;
    ${*$me}{'net_smtp_clns'} = *IO::Socket::SSL::DESTROY{CODE};
    *IO::Socket::SSL::DESTROY = \&Net::SMTP::DESTROY_SSLNS;
    $me->hello(${*$me}{'net_smtp_helo'} || "");
}
