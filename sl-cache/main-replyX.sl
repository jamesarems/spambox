#line 1 "sub main::replyX"
package main; sub replyX {
    my ($fh,$cli,$serIP,$cliIP) = @_;
    my $this = $Con{$fh};
    my $xinfo;
    my %seen;
    my $what = 'XCLIENT';
    $what = 'XFORWARD' if exists $Con{$cli}->{XFORWARD};
    d("info: sending $what info to $serIP");
    foreach (split(/\s+/o,$Con{$cli}->{$what})) {
        if (! $_ || ! defined *{'yield'} || exists $seen{$_}) {
            $seen{$_} = 1;
            next;
        } elsif ($_ eq 'REVERSE_NAME') {
            my $ptr = $Con{$cli}->{PTR};
            if (! $ptr && $cliIP !~ /$IPloopback/io) {
                $Con{$cli}->{PTR} = $ptr = [split( / /o, $PTRCache{$cliIP} )]->[2];
                if (! $ptr) {
                    &sigoffTry(__LINE__);
                    $Con{$cli}->{PTR} = $ptr = getRRData($cliIP,'PTR');
                    &sigonTry(__LINE__);
                    if ($ptr) {
                        PTRCacheAdd($Con{$cli}->{ip},0,$ptr)
                    } elsif ($lastDNSerror eq 'NXDOMAIN' || $lastDNSerror eq 'NOERROR') {
                        PTRCacheAdd($Con{$cli}->{ip},1,$ptr);
                    }
                }
            }
            $Con{$cli}->{PTR} = $ptr = $localhostname || 'localhost' if (! $ptr && $cliIP =~ /$IPloopback/io);
            $ptr ||= '[UNAVAILABLE]';
            $xinfo .= " REVERSE_NAME=$ptr";
        } elsif ($_ eq 'NAME') {
            my $name = $Con{$cli}->{PTR} || $Con{$cli}->{helo} || $cliIP || '[UNAVAILABLE]';
            $xinfo .= " NAME=$name";
        } elsif ($_ eq 'ADDR') {
            $xinfo .= $cliIP ? " ADDR=$cliIP" : " ADDR=[UNAVAILABLE]";
        } elsif ($_ eq 'PORT') {
            $xinfo .= $Con{$cli}->{port} ? " PORT=$Con{$cli}->{port}" : " PORT=[UNAVAILABLE]";
        } elsif ($_ eq 'PROTO') {
            my $proto = (lc $Con{$cli}->{orghelo} eq 'ehlo') ? 'ESMTP' : 'SMTP';
            $proto .= 'S' if "$cli" =~ /SSL/io;
            $xinfo .= " PROTO=$proto";
        } elsif ($_ eq 'HELO') {
            $xinfo .= $Con{$cli}->{helo} ? " HELO=$Con{$cli}->{helo}" : " HELO=[UNAVAILABLE]";
        } elsif ($_ eq 'IDENT') {
            $xinfo .= $Con{$cli}->{msgtime} ? " IDENT=$Con{$cli}->{msgtime} $Con{$cli}->{SessionID}" : " IDENT=[UNAVAILABLE]";
        } elsif ($_ eq 'SOURCE') {
            $xinfo .= $Con{$cli}->{acceptall} ? " SOURCE=LOCAL" : " SOURCE=REMOTE";
        } elsif ($_ eq 'LOGIN') {
            $xinfo .= $Con{$cli}->{userauth}{user} ? " LOGIN=$Con{$cli}->{userauth}{user}" : " LOGIN=[UNAVAILABLE]";
        } else {
            $xinfo .= " $_=[UNAVAILABLE]";
        }
        $seen{$_} = 1;
    }
    $Con{$cli}->{'save'.$what} = $Con{$cli}->{$what};
    delete $Con{$cli}->{$what};
    if ($xinfo) {
        $xinfo = "$what$xinfo";
        d("sent: $xinfo");
        mlog($cli,"info: sent - '$xinfo' to $serIP") if $ConnectionLog > 1;
        $this->{getline} = \&skipevery;
        sendque($fh, "$xinfo\r\n");
        delete $this->{isTLS};
        delete $Con{$cli}->{isTLS};
        return 1;
    }
    delete $this->{Xgetline};
    delete $this->{Xreply};
    return 0;
}
