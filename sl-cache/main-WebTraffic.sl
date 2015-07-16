#line 1 "sub main::WebTraffic"
package main; sub WebTraffic {
  my $fh=shift;
  my $buf = $WebCon{$fh};
  $WebCon{$fh} = '';
  my $done;
  my $haswritten = 1;
  my $hasread;
  my $ip;
  my $pending = 0;
  my $blocking = ("$fh" =~ /SSL/io) ? $HTTPSblocking : $HTTPblocking ;
  eval{$ip = $fh->peerhost(); $blocking = $WebIP{$ActWebSess}->{blocking} if exists $WebIP{$ActWebSess}->{blocking};};
  d("WEB: $ip");
  my $maxbuf = ("$fh" =~ /SSL/io) ? 16384 : 4096 ;
  eval{$pending = $fh->pending(); $maxbuf = $pending if $pending > 0;} if ("$fh" =~ /SSL/io);
  &ThreadMonitorMainLoop('MainLoop WebTraffic start');
  $fh->blocking($blocking) if ! $buf;
  $hasread = $fh->sysread($WebCon{$fh},$maxbuf);
  if ($hasread == 0 && "$fh" =~ /SSL/io && IO::Socket::SSL::errstr() =~ /SSL wants a/io) {
      mlog(0,"WebTraffic: SSL socket is not ready - will retry") if $ConnectionLog == 3 && ! $WebIP{$ActWebSess}->{sslerror};
      ThreadYield();
      $WebCon{$fh} = $buf;
      $WebIP{$ActWebSess}->{sslerror} ||= time;
      if (time - $WebIP{$ActWebSess}->{sslerror} > $SSLtimeout) {
          delete $WebIP{$ActWebSess}->{sslerror};
          WebDone($fh);
      }
      return;
  }
  delete $WebIP{$ActWebSess}->{sslerror};
  if($hasread > 0 or length($WebCon{$fh}) > 0) {
    local $_=$WebCon{$fh}=$buf.$WebCon{$fh};
    if(length($_) > 20600000) {
# throw away connections longer than 20M to prevent flooding
      WebDone($fh);
      return;
    }
    if(/Content-length: (\d+)/io) {
# POST request
      my $l=$1;
      if (/(.*?\n)\r?\n\r?(.*)/so && length($2) >= $l) {
        my $reqh=$1;
        my $reqb=$2;
        my $resp;
        my $tempfh;
        open($tempfh,'>',\$resp);
        binmode $tempfh;
        $done=webRequest($tempfh,$fh,\$reqh,\$reqb);
        close($tempfh);
        if ($httpchanged) {
            my $bl;
            if (exists $WebIP{$ActWebSess}->{blocking}) {
                $bl = $WebIP{$ActWebSess}->{blocking} ? '?blocking=1' : '?blocking=0' ;
            }
            my $prot = ("$fh" =~ /SSL/io) ? 'http:' : 'https:';
            $httpchanged = 0;
            mlog(0, "WebRequest changed HTTP(S): connected User-Agent: $head{'user-agent'}") if $ConnectionLog >= 2;
            $haswritten = &NoLoopSyswrite($fh, <<"EOT" ,$WebTrafficTimeout);
HTTP/1.1 200 OK
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head></head>
<body>
<script type=\"text/javascript\">
<!--
var mydom = window.location.host;
var myprot = '$prot';
alert('Switched to ' + myprot + '//' + mydom + '/' + ' - Please wait some seconds to let spambox finish change the configuration. It is recommended to restart SPAMBOX!');
window.location.href = myprot + '//' + mydom + '/$bl';
// -->
</script>
</body>
</html>
EOT
            &mlogWrite();
            &WebDone($fh);# if $head{'user-agent'} =~ /MSIE/io;
            return;
        }
        &WebPermission(\$resp);
        $resp =~ s/>([a-zA-Z_]+::[a-zA-Z_]+)(::[a-zA-Z_]+)?<\/a>/&setmodcol("$1$2")/geo if $currentPage eq 'Config';
        &ThreadMonitorMainLoop('MainLoop WebRequest (WP)');
        my ($resph,$se,$respb) = split(/(\n\r?\n\r?)/o,$resp,2);
        if ($se) {
          my $time=gmtime();
          $time=~s/(...) (...) +(\d+) (........) (....)/$1, $3 $2 $5 $4 GMT/o;
          $resph.="\nServer: SPAMBOX/$version$modversion";
          $resph.="\nDate: $time";
          if ($EnableHTTPCompression && $CanUseHTTPCompression && /Accept-Encoding: ([^\n]*)\n/io && $1=~/(gzip|deflate)/io) {
            my $enc=$1;
            if ($enc=~/gzip/io) {
# encode with gzip
              $respb=Compress::Zlib::memGzip($respb);
            } else {
# encode with deflate
              my $deflater=deflateInit();
              $respb=$deflater->deflate($respb);
              $respb.=$deflater->flush();
            }
            $resph.="\nContent-Encoding: $enc";
          }
          $resph.="\nContent-Length: ".length($respb);
          $haswritten = &NoLoopSyswrite($fh, "$resph\015\012\015\012$respb",$WebTrafficTimeout);
        }
# close connection
        if ($done || ! $haswritten) {
            &WebDone($fh);
        } else {
            $WebCon{$fh} = '';
        }
      }
    } elsif(/\n\r?\n/o) {
      my $resp;
      my $tempfh;
      open($tempfh,'>',\$resp);
      binmode $tempfh;
      $done=webRequest($tempfh,$fh,\$_,undef);
      close($tempfh);
      &ThreadMonitorMainLoop('MainLoop WebRequest 2');
      &WebPermission(\$resp);
      $resp =~ s/>([a-zA-Z_]+::[a-zA-Z_]+)(::[a-zA-Z_]+)?<\/a>/&setmodcol("$1$2")/geo if $currentPage eq 'Config';
      &ThreadMonitorMainLoop('MainLoop WebRequest 2 (WP)');
      my ($resph,$se,$respb) = split(/(\n\r?\n\r?)/o,$resp,2);
      if ($se) {
        my $time=gmtime();
        $time=~s/(...) (...) +(\d+) (........) (....)/$1, $3 $2 $5 $4 GMT/o;
        $resph.="\nServer: SPAMBOX/$version$modversion";
        $resph.="\nDate: $time";
        if ($EnableHTTPCompression && $CanUseHTTPCompression && /Accept-Encoding: ([^\n]*)\n/io && $1=~/(gzip|deflate)/io) {
          my $enc=$1;
          if ($enc=~/gzip/io) {
# encode with gzip
            $respb=Compress::Zlib::memGzip($respb);
          } else {
# encode with deflate
            my $deflater=deflateInit();
            $respb=$deflater->deflate($respb);
            $respb.=$deflater->flush();
          }
          $resph.="\nContent-Encoding: $enc";
        }
        $resph.="\nContent-Length: ".length($respb);
        $haswritten = &NoLoopSyswrite($fh, "$resph\015\012\015\012$respb",$WebTrafficTimeout);
       }
# close connection
       if ($done || ! $haswritten) {
           &WebDone($fh);
       } else {
           $WebCon{$fh} = '';
       }
    }
  } elsif ($hasread == 0) {
        my $error = $!;
        if ($error =~ /Resource temporarily unavailable/io) {
            d("WebTraffic - no more data - $error - pending: $pending");
            return ;
        }
        if ($pending) {
            d("WebTraffic - got no more (HTTPS) data but $pending Byte are pending - $error");
            return;
        } else {
            d("WebTraffic - no more data - $error");
            $pending = '';
        }
        mlog($fh,"info: no (more) data$pending readable (connection possibly closed by browser)") if (($ConnectionLog >= 2 or $pending) && ! $error);
        &WebDone($fh);
  } else {
# connection closed
    mlog(0,"info: no (more) HTTP/HTTPS data readable - $!") if $ConnectionLog >= 2;
    &WebDone($fh);
  }
}
