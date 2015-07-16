#line 1 "sub main::seterror"
package main; sub seterror {
    my($fh,$e,$done)=@_;
    d('seterror');

    my $this=$Con{$fh};
    $done = 1 if ($this->{lastcmd} !~ /^DATA/io &&       # end the connection if not send 250 and we are not in DATA part
                  ((! $send250OK && $this->{relayok}) ||
                  (($this->{ispip} || $this->{cip}) && ! $send250OKISP )));
    $done = 0 if ($this->{header} &&                    # receive the message if send 250 and we have still received data
                  $this->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o  &&
                  $this->{lastcmd} =~ /^DATA/io &&
                  ($send250OK || (($this->{ispip} || $this->{cip}) && $send250OKISP )));
    $this->{error}=$e;
    $done = 1 if $e =~ /^4/o;          # end the connection if the error Reply starts with 4xx
    if($done) {
        error($fh,".\r\n");
    } else {
        $this->{getline}=\&error;
    }
}
