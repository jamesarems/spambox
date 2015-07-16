#line 1 "sub main::error"
package main; sub error {
    my ( $fh, $l ) = @_;
    d('error');
    my $this = $Con{$fh};
    $this->{headerpassed} = 1;
    $this->{maillength} += length($l);
    if ( $l =~ /^\.[\r\n]+$/o
        || defined( $this->{bdata} ) && $this->{bdata} <= 0 )
    {
        my $reply;
        $reply = "421 <$myName> closing transmission";

        my $tlit = "[SMTP Reply]";
        $tlit = "[SMTP Status]" if ($this->{error} =~ /^4[0-9][0-9]/o );
        if ($this->{error} =~ /^5[0-9][0-9]/o ) {
            $tlit = "[SMTP Error]";
            if ( $send250OK || ( ($this->{ispip} || $this->{cip}) && $send250OKISP )) {
                $this->{error} = "250 OK";
                $tlit = "[SMTP Reply]";
            } else {
                $this->{error} =~ s/NOTSPAMTAG/NotSpamTagGen($fh)/ge;
            }
        }

        $this->{error} =~ s/(?:\r?\n)+$//o;
        my $out = $this->{error} . "\r\n";
        if ($this->{error} =~ /^250/o) {
          if ($this->{lastcmd} =~ /^DATA/io && $this->{header}) {     # we have received data - now waiting for QUIT
            sendque($fh,$out);
            $this->{getline} = \&errorQuit;
          } elsif ($this->{lastcmd} =~ /^DATA/io && ! $this->{header}) {   # no data received - close connection
            sendque($fh,"$reply\r\n");
            $this->{closeafterwrite} = 1;
            unpoll($fh,$readable);
            done2($this->{friend}) if (! exists $ConDelete{$this->{friend}});
          } else {                                                  # we are not in DATA part - send 250 and close connection
            sendque($fh,$out);
            sendque($fh,"$reply\r\n");
            $this->{closeafterwrite} = 1;
            unpoll($fh,$readable);
            done2($this->{friend}) if (! exists $ConDelete{$this->{friend}});
          }
        } else {                                               # no 250 - send the error and close the connection
            sendque($fh,$out);
            $reply = "221 <$myName> closing transmission" if ($this->{lastcmd} =~ /^QUIT/io);
            sendque($fh,"$reply\r\n") if $out !~ /^(?:4|5)/o && $this->{lastcmd} !~ /^QUIT/io;
            $this->{closeafterwrite} = 1;
            unpoll($fh,$readable);
            done2($this->{friend}) if (! exists $ConDelete{$this->{friend}});
        }
    }
    $this->{lastcmd} .= $this->{lastcmd} =~ /\(error\)/o ? '' : '(error)';
}
