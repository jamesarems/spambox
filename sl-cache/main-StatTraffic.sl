#line 1 "sub main::StatTraffic"
package main; sub StatTraffic {
    my $fh = shift;
    my $buf = $StatCon{$fh};
    $StatCon{$fh} = '';
    $fh->blocking($STATSblocking) unless $buf;
    &ThreadMonitorMainLoop('MainLoop StatTraffic start');
    if ( $fh->sysread( $StatCon{$fh}, 4096 ) > 0 ) {
        local $_ = $StatCon{$fh} = $buf . $StatCon{$fh};
        if ( length($_) > 1030000 ) {

            # throw away connections longer than 1M to prevent flooding
            WebDone($fh);
            return;
        }
        if (/Content-length: (\d+)/io) {

            # POST request
            my $l = $1;
            if ( /(.*?\n)\r?\n\r?(.*)/so && length($2) >= $l ) {
                my $reqh = $1;
                my $reqb = $2;
                my $resp;
                my $tempfh;
                open( $tempfh, '>', \$resp );
                binmode $tempfh;
                statRequest( $tempfh, $fh, \$reqh, \$reqb );
                close($tempfh);

                if ( index($resp , "\n\n") >= 0 or index($resp , "\n\r\n\r") >= 0 ) {
                    my ($resph,$respb) = split(/\n\r?\n\r?/o, $resp, 2);
                    my $time  = gmtime();
                    $time =~
s/(...) (...) +(\d+) (........) (....)/$1, $3 $2 $5 $4 GMT/o;
                    $resph .= "\nServer: ASSP/$version$modversion";
                    $resph .= "\nDate: $time";
                    $respb =~ s/not healthy/$webStatNotHealthyResp/o;
                    $respb =~ s/([^n][^o][^t][^ ])healthy/$1$webStatHealthyResp/o;
                    if (   $EnableHTTPCompression
                        && $CanUseHTTPCompression
                        && /Accept-Encoding: ([^\n]*)\n/io
                        && $1 =~ /(gzip|deflate)/io )
                    {
                        my $enc = $1;
                        if ( $enc =~ /gzip/io ) {

                            # encode with gzip
                            $respb = Compress::Zlib::memGzip($respb);
                        } else {
                            # encode with deflate
                            my $deflater = deflateInit();
                            $respb = $deflater->deflate($respb);
                            $respb .= $deflater->flush();
                        }
                        $resph .= "\nContent-Encoding: $enc";
                    }
                    $resph .= "\nContent-Length: " . length($respb);
                    &NoLoopSyswrite( $fh, "$resph\015\012\015\012$respb",$WebTrafficTimeout );
                }
# close connection
                &WebDone($fh);
            }
        } elsif (/(.*)?\r?\n(\r)?\n(.*)?/so) {
            my $http = $1;
            my $cr   = $2;
            my $dat  = $3;
            my $how  = ( $http =~ /^stat/io );
            $http =~ s/\r//go;
            my $resp;
            my $tempfh;
            if ($http) {
                open( $tempfh, '>', \$resp );
                binmode $tempfh;
                statRequest( $tempfh, $fh, \$http ,\$dat);
                close($tempfh);
            }
            else {
                my $currStat = &StatusASSP();
                $resp =
                  ( $currStat =~ /not healthy/io )
                  ? "$webStatNotHealthyResp\n"
                  : "$webStatHealthyResp\n";
            }
            if ( index($resp , "\n\n") >= 0 or index($resp , "\n\r\n\r") >= 0 ) {
                my ($resph,$respb) = split(/\n\r?\n\r?/o,$resp , 2);
                $resph = $how ? '' : $resph . "\n";
                my $time  = gmtime();
                $time =~
                  s/(...) (...) +(\d+) (........) (....)/$1, $3 $2 $5 $4 GMT/o;
                $resph .= "Server: ASSP/$version$modversion";
                $resph .= "\nDate: $time";
                if (  !$how
                    && $EnableHTTPCompression
                    && $CanUseHTTPCompression
                    && /Accept-Encoding: ([^\n]*)\n/io
                    && $1 =~ /(gzip|deflate)/io )
                {
                    my $enc = $1;
                    if ( $enc =~ /gzip/io ) {
                        # encode with gzip
                        $respb = Compress::Zlib::memGzip($respb);
                    } else {
                        # encode with deflate
                        my $deflater = deflateInit();
                        $respb = $deflater->deflate($respb);
                        $respb .= $deflater->flush();
                    }
                    $resph .= "\nContent-Encoding: $enc";
                }
                if ($how) {
                    $resph .= "\n";
                    if ($cr) {
                        $resph =~ s/(?:$cr\n)+/$cr\n/g;
                        $respb =~ s/(?:$cr\n)+/$cr\n/g;
                    } else {
                        $resph =~ s/\n+/\n/go;
                        $respb =~ s/\n+/\n/go;
                    }
                }
                else {
                    $resph .=
                      "\nContent-Length: " . length($respb) . "\r\n\r\n";
                }
                &NoLoopSyswrite( $fh, "$resph$respb",$WebTrafficTimeout );
            }
            else {
                if ($cr) {
                    $resp =~ s/(?:$cr?\n)+/$cr\n/g;
                } else {
                    $resp =~ s/\n+/\n/go;
                }
                &NoLoopSyswrite( $fh, "$resp",$WebTrafficTimeout );
            }
# close connection
            &WebDone($fh);
        }
    }
    else {
# connection closed
        &WebDone($fh);
    }
}
