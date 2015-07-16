#line 1 "sub main::DNSSocketsCleanup"
package main; sub DNSSocketsCleanup {
    return unless $DNSReuseSocket;
    eval {
    if (@_) {
        my $select = IO::Select->new();
        for (@_) {
            $select->add($_) if ref $_;
        }
        mlog(0,"info: cleanup existing DNS sockets - ".$select->handles()) if $DebugSPF;
        # cleanup DNS the sockets
        while (my @ready = $select->can_read( $minSelectTime )) {
            my @nofin;
            my $msg;
            map {
                $_->recv($msg, 4000 );
                if ($msg) {
                   push @nofin, $_;
                   if ($DebugSPF) {
                       mlog(0,"info: cleanedup old data from DNS sockets for ".$_->peerhost);
                       if (my $packet = Net::DNS::Packet->new(\$msg)) {
                           for ($packet->question) {
                               mlog(0,"cleanedup DNS-question: ".$_->string);
                           }
                           for ($packet->answer) {
                               mlog(0,"cleanedup DNS-answer: ".$_->string);
                           }
                       }
                   }
                }
            } @ready;
            last unless @nofin;
        }
    }
    };
}
