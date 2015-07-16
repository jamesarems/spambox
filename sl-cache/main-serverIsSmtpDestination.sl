#line 1 "sub main::serverIsSmtpDestination"
package main; sub serverIsSmtpDestination {
  my $server=shift;
  d('serverIsSmtpDestination');
  my $peeraddr=$server->peerhost().':'.$server->peerport();
  my $destination;
  foreach my $destinationA (split(/\s*\|\s*/o, $smtpDestination)) {
      if ($destinationA  =~ /^(_*INBOUND_*:)?(\d+)$/o){
          if (exists $crtable{$Con{$Con{$server}->{friend}}->{localip}}) {
              $destination=$crtable{$Con{$Con{$server}->{friend}}->{localip}};
          } else {
              $destination = $Con{$Con{$server}->{friend}}->{localip} .':'.$2;
          }
      } else {
          $destination = $destinationA;
      }
      $destination =~ s/^SSL://io;
      return 1 if $peeraddr eq $destination || $peeraddr eq $destination.':25';
  }
  return 0;
}
