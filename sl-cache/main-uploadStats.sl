#line 1 "sub main::uploadStats"
package main; sub uploadStats {
 d('uploadStats');
 my ($peeraddress,$connect,$hostaddress, $target);
 if ($proxyserver) {
        mlog( 0, "uploading stats via proxy:$proxyserver" ) if $MaintenanceLog;
        my $user = $proxyuser ? "$proxyuser:$proxypass\@": '';
        $peeraddress = $user . $proxyserver;
        $hostaddress = $proxyserver;
        $connect =
          'POST http://assp.sourceforge.net/cgi-bin/assp_stats HTTP/1.0';
        $target = $proxyserver;
 } else {
        mlog( 0, 'uploading stats via direct connection' ) if $MaintenanceLog;
        $peeraddress = 'assp.sourceforge.net:80';
        $hostaddress = 'assp.sourceforge.net';
        $connect     = "POST /cgi-bin/assp_stats HTTP/1.1
Host: assp.sourceforge.net";
        $target = $hostaddress;
 }
 my $s = $CanUseIOSocketINET6
         ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$peeraddress,Timeout=>2,&getDestSockDom($hostaddress),&getLocalAddress('HTTP',$target))
         : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$peeraddress,Timeout=>2,&getLocalAddress('HTTP',$target));
 if($s) {
  my %UploadStats = ();
  my $buf;
  {lock(%Stats) if (is_shared(%Stats));
        my %tots=statsTotals();

        %UploadStats = %Stats;

        $UploadStats{upproto_version}      = 2;
        $UploadStats{timenow}              = time;
        $UploadStats{connects}             = $tots{smtpConnTotal};
        $UploadStats{messages}             = $tots{msgTotal};
        $UploadStats{spams}                = $tots{msgRejectedTotal} - $Stats{bspams};
        delete $UploadStats{nextUpload};
        $UploadStats{denyConnection} += $UploadStats{denyConnectionA};
        delete $UploadStats{denyConnectionA};
        $UploadStats{dkim} += $UploadStats{dkimpre}; delete $UploadStats{dkimpre};
  }
  my $content=join("\001",%UploadStats);
  my $len=length($content);
  $connect.="
Content-Type: application/x-www-form-urlencoded
Content-Length: $len

$content";
  eval{$s->blocking(0);};
  NoLoopSyswrite( $s , $connect,0);
  sleep(1);
  $ThreadIdleTime{$WorkerNumber} += 1;
  eval{$s->sysread($buf, 4096);};
  eval{$s->close;};
 } else {
  mlog(0,"unable to connect to stats server");
 }
 $Stats{nextUpload} = $nextStatsUpload = time+3600*8;
}
