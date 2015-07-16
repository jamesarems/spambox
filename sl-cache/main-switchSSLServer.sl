#line 1 "sub main::switchSSLServer"
package main; sub switchSSLServer {
    my $fh =shift;
    my $sslfh;
    my $try = 4;
    eval{$fh->blocking(1);};
    $sslfh = IO::Socket::SSL->start_SSL($fh,{
             SSL_startHandshake => 1,
             getSSLParms(0)
             });
    while ($try-- && "$sslfh" !~ /SSL/io && ($IO::Socket::SSL::SSL_ERROR == eval('SSL_WANT_READ') ? 1 : $IO::Socket::SSL::SSL_ERROR == eval('SSL_WANT_WRITE') ) && $SSLRetryOnError)
    {
         &ThreadYield();
         Time::HiRes::sleep(0.5);
         $ThreadIdleTime{$WorkerNumber} += 0.5;
         mlog($fh,"info: retry ($try) SSL negotiation - peer socket was not ready");

         $sslfh = IO::Socket::SSL->start_SSL($fh,{
             SSL_startHandshake => 1,
             getSSLParms(0)
             });
    }
    if ("$sslfh" =~ /SSL/io) {
        eval{$sslfh->blocking(0);};
    } else {
        eval{$fh->blocking(0);};
    }
    return $sslfh,$fh;
}
