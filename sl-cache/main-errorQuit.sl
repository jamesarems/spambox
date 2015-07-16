#line 1 "sub main::errorQuit"
package main; sub errorQuit {
    my ( $fh, $l ) = @_;
    d("errorQuit - $l");
    my $this = $Con{$fh};
    my $reply = "421 <$myName> closing transmission";
    if ($l =~ /^QUIT/io) {
        $reply = "221 <$myName> closing transmission";
    }
    sendque($fh,"$reply\r\n");
    $this->{closeafterwrite} = 1;
    unpoll($fh,$readable);
    $l =~ s/\r|\n//go;
    ($this->{lastcmd}) = $l =~ /([a-z]+\s?[a-z]*)/io;
    $this->{lastcmd} = $l unless $this->{lastcmd};
    push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
    # detatch the friend -- closing connection to server & disregarding message
    done2($this->{friend}) if (! exists $ConDelete{$this->{friend}});
}
