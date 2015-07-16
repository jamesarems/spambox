#line 1 "sub main::getfh4fileno"
package main; sub getfh4fileno {
    my ($fno,$sockType,$fhInfo) = @_;
    my $fhh;
    my $ssl;
    $fhInfo =~ /^(.+)?:(\d+)$/o;
    my ($ipg,$portg) = ($1,$2);

    my %Domain;
    d("getfh4fileno: $ipg $portg $sockType");

    if ($sockType eq 'IO::Socket::INET') {
        $fhh = $sockType->new();
        $fhh->fdopen($fno, '+>');
        return $fhh;
    } elsif ($sockType eq 'IO::Socket::INET6') {
        %Domain = ($fhInfo =~ /^$IPv4Re:$PortRe$/o)
                   ? ('Domain' => AF_INET ,'LocalAddr' => $ipg)
                   : ('Domain' => AF_INET6,'LocalAddr' => $ipg);
        $fhh = $sockType->new(%Domain);
        $fhh->fdopen($fno, '+>');
        return $fhh;
    } else {   # IO::Socket::SSL
        if ($CanUseIOSocketINET6) {
            if ($fhInfo =~ /^$IPv4Re:$PortRe$/o) {
                %Domain = ('Domain' => AF_INET ,'LocalAddr' => $ipg);
            } else {
                %Domain = ('Domain' => AF_INET6,'LocalAddr' => $ipg);
            }
            $fhh = IO::Socket::INET6->new(%Domain);
        } else {
            $fhh = IO::Socket::INET->new();
        }
        $fhh->fdopen($fno, '+>');
    }

    my $fail = 0;
    eval{$fhh->blocking(1);};
    my $sslParm = {  SSL_startHandshake => 0,
                     %Domain,
                     getSSLParms(1)
                  };
    eval{
        $ssl = IO::Socket::SSL->start_SSL($fhh,$sslParm);
        if ("$ssl" !~ /SSL/io ) {
             mlog($fhh, "error: Couldn't negotiate SSL $fhInfo : ".IO::Socket::SSL::errstr()) unless $inSIG;
             $fail = 1;
             eval{$fhh->blocking(0);};
        }
    };
    if ($@) {
         mlog($fhh, "error: Couldn't negotiate SSL $fhInfo - $@ - ".IO::Socket::SSL::errstr()) unless $inSIG;
         eval{$fhh->blocking(0);};
         return 0;
    }
    return 0 if $fail;
    eval{$ssl->blocking(0);};
    return $ssl;
}
