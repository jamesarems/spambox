#line 1 "sub main::isnotspam"
package main; sub isnotspam {
  my ($fh,$done)=@_;
  d('isnotspam');
  my $this=$Con{$fh};
  my $server=$this->{friend};

# it's time to merge our header with client's one
  $this->{myheader}="X-Assp-Version: $version$modversion on $myName\r\n" . $this->{myheader}
      if ! $this->{relayok} && $this->{myheader} !~ /X-Assp-Version:.+? on \Q$myName\E/;

  makeMyheader($fh,0,0,'');
  addMyheader($fh) if ($done && $this->{myheader});  # &white body will do it later

  sendquedata($server, $fh ,\$this->{header}, $done);
  $this->{headerpassed} = 1;
  
  if($done) {
    $this->{getline}=\&getline;
  } else {
    $this->{getline}=\&whitebody;
  }
}
