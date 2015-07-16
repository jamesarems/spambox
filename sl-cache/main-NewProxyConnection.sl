#line 1 "sub main::NewProxyConnection"
package main; sub NewProxyConnection {
   my $fh=shift;
   my $fnoC;
   my $fnoS;
   checkVersionAge();
   my $mlog = $inSIG ? \&mlog_S : \&mlog ;
   my $d = $inSIG ? \&d_S : \&d ;
   $d->('NewProxyConnection');
   &ThreadMonitorMainLoop('MainLoop NewProxyConnection');
   delete $SocketCalls{$fh};
   my $client=$fh->accept;
   if ( ! $client) {
     threadConDone($fh);
     close($fh);
     threads->yield;
     $trqueue->enqueue("failed");       # tell the main thread that we are not connected!
     threads->yield;
     $mlog->(0,"error: $WorkerName accept to proxy client failed $fh");
     $mlog->(0,"info: $WorkerName freed Main_Thread") if($WorkerLog >= 2);
     exists $Con{$fh} && delete $Con{$fh};
     return;
   }
   threadConDone($fh);
   close($fh);
   exists $Con{$fh} && delete $Con{$fh};
   $fnoC = fileno($client);
   threads->yield;
   $trqueue->enqueue("ok");       # tell the main thread that we are connected!
   threads->yield;
   $mlog->(0,"info: $WorkerName freed Main_Thread") if($WorkerLog >= 2);
   my $ip=$client->peerhost();
   my $port=$client->peerport();
   my $lip=$client->sockhost;
   my $lport=$client->sockport;
   my ($dest,$allow) = split(/<=/o,$Proxy{$lip.':'.$lport});
   $allow =~ s/,/\|/go;
   my $allowProxyConnectionsFrom=$allow;

   ConfigMakeIPRe ('allowProxyConnectionsFrom',$allowProxyConnectionsFrom,$allowProxyConnectionsFrom );
   delete $ConfigWatch{'allowProxyConnectionsFrom'};
   foreach (keys %GroupWatch) {
       delete $GroupWatch{$_}->{'allowProxyConnectionsFrom'};
       delete $GroupWatch{$_} unless scalar keys %{$GroupWatch{$_}};
   }

   if ($allow && ! matchIP($ip,'allowProxyConnectionsFrom', 0, $inSIG)) {
     $mlog->(0,"proxy connection to $lip:$lport from $ip:$port rejected");
     threadConDone($client);
     close($client);
     return;
   }

   my $server = $CanUseIOSocketINET6
                ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$dest,Timeout=>2,&getDestSockDom($dest),&getLocalAddress('SMTP',$dest))
                : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$dest,Timeout=>2,&getLocalAddress('SMTP',$dest));
   if (!$server) {
         $mlog->(0,"error: couldn't create proxy socket to $dest -- aborting connection: $!") ;
         threadConDone($client);
         close($client);
         return;
   }
   $fnoS = fileno($server);
   addProxyfh($client,$server);
   $Con{$client}->{SessionID} = uc "$client";
   $Con{$client}->{SessionID} =~ s/^.+?\(0[xX]([^\)]+)\).*$/$1/o;
   $Con{$client}->{client}   = $client;
   $Con{$client}->{self}     = $client;
   $Con{$client}->{server}   = $server;
   $Con{$client}->{ip}       = $ip;
   $Con{$client}->{port}     = $port;
   $Con{$client}->{localip}  = $lip;
   $Con{$client}->{localport}= $lport;
   $Con{$client}->{type}     = 'C';
   $Con{$client}->{fno}      = $fnoC;
   $Con{$server}->{type}     = 'S';
   $Con{$server}->{fno}      = $fnoS;
   $Con{$server}->{self}     = $server;
   $d->("Proxy-Connected: SID($Con{$client}->{SessionID}) $client -- $server");
}
