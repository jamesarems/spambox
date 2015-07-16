#line 1 "sub main::ConfigChangeRelayPort"
package main; sub ConfigChangeRelayPort {my ($name, $old, $new, $init)=@_;
    unless ($relayHost && $new) {
        if(@lsnRelay) {
          foreach my $Relay (@lsnRelay) {
            unpoll($Relay,$readable);
            unpoll($Relay,$writable);
            close($Relay);
            delete $SocketCalls{$Relay};
          }
          $$name = $Config{$name}=$new;
          mlog(0,"AdminUpdate: relay port disabled");
          return '<br />relay port disabled';
        } else {
          $$name = $Config{$name}=$new;
          return "<br />relayHost ($relayHost) and relayPort ($new) must be defined to enable relaying";
        }
    }
    my $highport = 1;
    foreach my $port (split(/\|/o,$new)) {
        if ($port =~ /^.+:([^:]+)$/o) {
            if ($1 < 1024) {
                $highport = 0;
                last;
            }
        } else {
            if ($port < 1024) {
                $highport = 0;
                last;
            }
        }
    }
    if($> == 0 || $highport || $^O eq "MSWin32") {

        # change the listenport
        $$name = $Config{$name}=$new;
        if(@lsnRelay) {
            foreach my $Relay (@lsnRelay) {
                unpoll($Relay,$readable);
                unpoll($Relay,$writable);
                close($Relay);
                delete $SocketCalls{$Relay};
            }
        }
        my ($lsnRelay,$lsnRelayI)=newListen($relayPort,\&ConToThread,1);
        @lsnRelay = @$lsnRelay; @lsnRelayI = @$lsnRelayI;
        for (@$lsnRelayI) {s/:::/\[::\]:/o;}
        mlog(0,"AdminUpdate: listening for relay connections at @$lsnRelayI ");
        return '';
    } else {
        $$name = $Config{$name}=$new;
        # don't have permissions to change
        mlog(0,"AdminUpdate: request to listen on new relay port $new (changed from $old) -- restart required; euid=$>");
        return "<br />Restart required; euid=$><script type=\"text/javascript\">alert(\'new relay port - SPAMBOX-Restart required\');</script>";
    }
}
