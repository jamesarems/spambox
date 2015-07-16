#line 1 "sub Net::SMTP::SSL::NSSL_new"
package Net::SMTP::SSL; sub NSSL_new {
  my $self = shift;
  return unless $self;
  my $type = ref($self) || $self;
  my ($host, %arg);
  if (@_ % 2) {
    $host = shift;
    %arg  = @_;
  }
  else {
    %arg  = @_;
    $host = delete $arg{Host};
  }
  my %sslParms = $arg{sslParms} ? %{$arg{sslParms}} : &main::getSSLParms(0);
  $sslParms{SSL_startHandshake} = 1 unless $arg{sslParms};
  
  $IO::Socket::SSL::DEBUG = $main::SSLDEBUG;

  $arg{LocalAddr} ||= &main::getLocalAddress('SMTP',$host) unless exists $arg{LocalAddr};
  delete $arg{LocalAddr} unless $arg{LocalAddr};

  my $obj = $type->SUPER::new(
      PeerAddr => $host,
      PeerPort => $arg{Port} || 465,
      LocalAddr => $arg{LocalAddr},
      LocalPort => $arg{LocalPort},
      Proto     => 'tcp',
      Timeout   => (defined $arg{Timeout}
      ? $arg{Timeout}
      : 120),
      %sslParms
      );

  return unless defined $obj;

  $obj->autoflush(1);

  $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

  unless ($obj->response() == eval('CMD_OK')) {
    my $err = ref($obj) . ": " . $obj->code . " " . $obj->message;
    $obj->close();
    $@ = $err;
    return;
  }

  ${*$obj}{'net_smtp_exact_addr'} = $arg{ExactAddresses};
  ${*$obj}{'net_smtp_host'}       = $host;
  ${*$obj}{'net_smtp_ssl'} = 1;
  
  (${*$obj}{'net_smtp_banner'}) = $obj->message;
  (${*$obj}{'net_smtp_domain'}) = $obj->message =~ /\A\s*(\S+)/;

  unless ($obj->hello($arg{Hello} || "")) {
    my $err = ref($obj) . ": " . $obj->code . " " . $obj->message;
    $obj->close();
    $@ = $err;
    return;
  }

  $obj;
}
