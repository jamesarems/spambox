#line 1 "sub RBL::new"
package RBL; sub new {
    # This avoids compile time errors if Net::DNS is not installed.
    # The error will be returned on the lookup function call.
    &DESTROY();
    if ($main::CanUseDNS) {
        require Net::DNS::Packet;
    }
    if ($main::CanUseAsspSelfLoader) {
        require IO::Socket; IO::Socket->import();
        require IO::Select; IO::Select->import();
    }
    my($class, %args) = @_;
    my $self;

    return unless @{$args{server}};

    if ($args{reuse} && ref(${'main::'.$args{reuse}}) eq $class) {
       $self = ${'main::'.$args{reuse}};
       if ( join('',@{$self->{server}}) ne join('',@{$args{server}}) ) {
           eval{$_->close if $_;} for (@{$self->{sockets}});
           @{$self->{sockets}} = ();
           &main::mlog(0,"RBL: reused - new DNS Servers") if $diagnostic;
       } elsif (@{$args{server}} != @{$self->{sockets}}) {
           eval{$_->close if $_;} for (@{$self->{sockets}});
           @{$self->{sockets}} = ();
           &main::mlog(0,"RBL: reused - missmatch server <-> socket") if $diagnostic;
       } else {
           &main::mlog(0,"RBL: reused - OK") if $diagnostic;
       }
    } else {
        $self = {
            lists       => [ lists() ],
            query_txt   => 0,
            max_time    => 10,
            timeout     => 1,
            max_hits    => 3,
            max_replies => 6,
            udp_maxlen  => 4000,
            server      => ($main::CanUseIOSocketINET6 ? ['[::1]'] : ['127.0.0.1']),
            tolog       => 0
        };
        bless $self, $class;
        @{$self->{sockets}} = ();
        ${'main::'.$args{reuse}} = $self if $args{reuse};
        &main::mlog(0,"RBL: new RBL object created") if $diagnostic;
    }
    foreach my $key(keys %args) {
        next if $key eq 'reuse';
        defined($self->{ $key })
            or return "Invalid key: $key";
        $self->{ $key } = $args{ $key };
    }
    $self->{server} = [shift @{$self->{server}}] unless defined *{'main::yield'};
    @{$self->{ID}} = ();
    return $self;
}
