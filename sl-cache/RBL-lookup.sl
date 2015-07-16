#line 1 "sub RBL::lookup"
package RBL; sub lookup {
    return "Net::DNS package required" unless $main::CanUseDNS;
    my($self, $target, $type) = @_;
    @{$self->{ID}} = ();
    @{$self->{server}} = @{$self->{server}}[0..($main::DNSServerLimit - 1)] if $main::DNSServerLimit;
    my $start_time = time;
    my $qtarget;
    my $dur;
    my @ok;
    my @failed;
    my $isip = 0;
    $target =~ s/[^\w\-\.:].*$//o if $type ne 'URIBL';
    if ($target=~/^$main::IPv4Re$/o) {
        $qtarget = join ('.', reverse(split /\./o, $target));
        $isip = 1;
    } elsif ($target=~/^$main::IPv6Re$/o) {
        $qtarget = &main::ipv6hexrev($target,36) or return "IPv6 addresses are not supported";
        $isip = 2;
    } else {
        $qtarget=$target;
    }
    my $deadline = time + $self->{ max_time };
    my @sock = @{$self->{sockets}};
    my $newsockets;
    
    if (! @sock) {
        for (@{$self->{server}}) {
            my $sock = $main::CanUseIOSocketINET6
                       ? IO::Socket::INET6->new(Proto=>'udp',PeerAddr=>$_,PeerPort=>53,&main::getDestSockDom($_),&main::getLocalAddress('DNS',$_))
                       : IO::Socket::INET->new(Proto=>'udp',PeerAddr=>$_,PeerPort=>53,&main::getLocalAddress('DNS',$_));
            push @sock, $sock if $sock;
        }
        &main::mlog(0,'RBL: created '.@sock.' new RBL-DNS sockets') if $diagnostic;
        $newsockets = 1;
    }
    if (! @sock) {
        @{$self->{sockets}} = ();
        $main::nextDNSCheck = $main::lastDNScheck + 5;
        return "Failed to create any UDP client for DNS queries";
    }
    for (@sock) {
        $_->blocking(0) if $_->blocking;
    }
    @{$self->{sockets}} = @sock;
    if (! $newsockets) {
        my $select = IO::Select->new();
        $select->add($_) for @sock;
        my $numsock = scalar @sock;
        # cleanup the sockets
        while ($numsock && (my @ready = $select->can_read( $main::minSelectTime )) ) {
            my @nofin;
            my $msg;
            map {
                $_->recv($msg, $self->{udp_maxlen} );
                push @nofin, $_ if $msg;
                &main::mlog(0,'RBL: socket buffer cleaned') if $diagnostic;
            } @ready;
            last unless @nofin;
        }
    }
    my $sn = 0;
    my @availsock;
    my %regsock;
    if ( $self->{ query_txt } ) {
      foreach my $list(@{ $self->{ lists } }) {
        if (length($qtarget.$list) > 62 && $type ne 'URIBL' && $isip != 2) {
          eval{$_->close if $_;} for (@sock);
          @{$self->{sockets}} = ();
          return "domain name too long";
        }
        if ($list && !($type eq 'URIBL' && lc $list eq 'dbl.spamhaus.org' && $isip)) {
            my($msg_a, $msg_t) = mk_packet($self, $qtarget, $list);
            $list =~ s/.*?\$DATA\$\.?//io;
            foreach ($msg_a, $msg_t) {
                my $redo;
                if ($sock[$sn]->send($_)) {
                    if (! exists $regsock{$sock[$sn]} ) {
                        push @availsock , $sock[$sn];
                        $regsock{$sock[$sn]} = eval{$sock[$sn]->peerhost()} . '[:' . eval{$sock[$sn]->peerport()}.']';
                    }
                    my $t = ($_ eq $msg_a) ? 'A' : 'TXT';
                    &main::mlog(0,"sending DNS($t)-query to $regsock{$sock[$sn]} on $list for $type checks on $target") if $self->{tolog};
                } else {
                    eval{$sock[$sn]->close;};
                    splice(@sock,$sn,1);
                    $redo = 1;
                }
                $sn = 0 if ++$sn >= scalar @sock;
                last unless scalar @sock;
                redo if $redo;
            }
            if (! scalar @availsock && ! scalar @sock) {
                @{$self->{sockets}} = ();
                return "send: $!";
            }
        }
      }
    } else {
        foreach my $list(@{ $self->{ lists } }) {
          if (length($qtarget.$list) > 62 && $type ne 'URIBL' && $isip != 2) {
            eval{$_->close if $_;} for (@sock);
            @{$self->{sockets}} = ();
            return "domain name too long";
          }
          if ($list && !($type eq 'URIBL' && lc $list eq 'dbl.spamhaus.org' && $isip)) {
              my $msg = mk_packet($self, $qtarget, $list);
              $list =~ s/.*?\$DATA\$\.?//io;
              foreach ($msg,0) {
                  last unless $_;
                  my $redo;
                  if ($sock[$sn]->send($_)) {
                      if (! exists $regsock{$sock[$sn]} ) {
                          push @availsock , $sock[$sn];
                          $regsock{$sock[$sn]} = eval{$sock[$sn]->peerhost()} . '[:' . eval{$sock[$sn]->peerport()}.']';
                      }
                      &main::mlog(0,"sending DNS(A)-query to $regsock{$sock[$sn]} on $list for $type checks on $target") if $self->{tolog};
                  } else {
                      eval{$sock[$sn]->close;};
                      splice(@sock,$sn,1);
                      $redo = 1;
                  }
                  $sn = 0 if ++$sn >= scalar @sock;
                  last unless scalar @sock;
                  redo if $redo;
              }
              if (! scalar @availsock && ! scalar @sock) {
                  @{$self->{sockets}} = ();
                  return "send: $!";
              }
          }
        }
    }
    @sock = @availsock;
    if (@{$self->{sockets}} != @sock) {
        @{$self->{sockets}} = ();
        &main::mlog(0,'RBL: object sockets closed') if $diagnostic;
    }

    $self->{ results } = {};
    $self->{ txt } = {};

    my $needed = 0;
    if ($self->{ max_replies} > @{ $self->{ lists } }) {
      $needed = @{ $self->{ lists } };
    } else {
      $needed = $self->{ max_replies };
    }

    my $hits = my $replies = 0;

    my $select = IO::Select->new();
    $select->add($_) for @sock;
    my $numsock = scalar @sock;
    # Keep receiving packets until one of the exit conditions is met:
    &main::mlog(0,"Commencing $type checks on '$target'") if $self->{tolog};
    my $countansw = 0;
    while ($needed && time < $deadline) {
      my @msg = ();
      my $st = Time::HiRes::time();
      if ($numsock && (my @ready = $select->can_read( $self->{timeout} || 2 )) ) {

        my $qt = Time::HiRes::time() - $st;
        $main::DNSmaxQueryTime = &main::max($main::DNSmaxQueryTime,$qt);
        $main::DNSminQueryTime = &main::min($main::DNSminQueryTime,$qt);
        $main::DNSsumQueryTime += $qt;
        $main::DNSQueryCount++;

        map {
            if ($_->recv(my $msg, $self->{udp_maxlen} )) {
                push @msg, $msg;
            } else {
                $select->remove($_);
                eval{$_->close;};
                $numsock--;
                @{$self->{sockets}} = ();
            }
        } @ready;
        if (! @msg && ! $numsock) {
            @{$self->{sockets}} = ();
            return "recv: $!";
        }
        next unless @msg;
      } elsif (! $numsock) {
        @{$self->{sockets}} = ();
        $main::ThreadIdleTime{$main::WorkerNumber} += Time::HiRes::time() - $st;
        return "recv: $!";
      } else {
        next; # there are no data on socket -> next loop
      }
      $main::ThreadIdleTime{$main::WorkerNumber} += Time::HiRes::time() - $st;
      $dur = time - $start_time;
      while (my $msg = shift @msg) {
        my ($domain, $res, $rtype) = decode_packet($self,$msg);
        next if $rtype eq 'TXT' || $rtype eq 'INVALID';
        $countansw++;
        unless ($domain) {
            $needed --;
            next ;
        }
        next if exists $self->{ results }{ $domain };
        $replies ++;
        if ($res) {
          my $ret = $domain;
          $ret =~ s/^\Q$qtarget\E\.//;
          push @failed, $ret unless grep(/\Q$ret\E/,@failed);

          $hits ++;
          $self->{ results }{ $domain } = $res;
          &main::mlog(0,"$type: stored <$res> for $domain in results") if $self->{tolog};
          if (! $main::Showmaxreplies &&
              ($hits >= $self->{ max_hits } || $replies >= $self->{ max_replies })
             ) {

              $dur = time - $start_time;
              &main::mlog(0,"got $countansw answers, $replies replies and $hits hits after $dur seconds for $type checks on '$target'") if $self->{tolog};
              &main::mlog(0,"got OK replies from (@ok) - NOTOK replies from (@failed) for $type on '$target'") if $self->{tolog};
#              eval{$_->close if $_;} for (@sock);
              return 1;
          }
        } else {
            my $ret = $domain;
            $ret =~ s/^\Q$qtarget\E\.//;
            push @ok, $ret unless grep(/\Q$ret\E/,@ok);
        }
        $needed --;
      }
    }
    $dur = time - $start_time;
    &main::mlog(0,"got $countansw answers, $replies replies and $hits hits after $dur seconds for $type checks on '$target'") if $self->{tolog};
    &main::mlog(0,"got OK replies from (@ok) - NOTOK replies from (@failed) for $type on '$target'") if $self->{tolog};
    &main::mlog(0,"Completed $type checks on '$target'") if $self->{tolog};
#    eval{$_->close if $_;} for (@sock);
    return 1;
}
