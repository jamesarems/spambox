#line 1 "sub ASSP::Syslog::send"
package ASSP::Syslog; sub send {
    my $self  = shift;
    my $msg   = shift;
    my %par   = @_;
    my %local = %$self;
    foreach ( keys %par ) {
        $local{$_} = $par{$_};
    }

    my $pid = ( $local{Pid} =~ /^\d+$/ ) ? "\[$local{Pid}\]" : "";
    my $facility_i = $syslog_facilities{ $local{Facility} } || 21;
    my $priority_i = $syslog_priorities{ $local{Priority} } || 3;

    my $d = ( ( $facility_i << 3 ) | ($priority_i) );

    my @time = localtime();
    my $ts =
        $month[ $time[4] ] . " "
      . ( ( $time[3] < 10 ) ? ( " " . $time[3] ) : $time[3] ) . " "
      . ( ( $time[2] < 10 ) ? ( "0" . $time[2] ) : $time[2] ) . ":"
      . ( ( $time[1] < 10 ) ? ( "0" . $time[1] ) : $time[1] ) . ":"
      . ( ( $time[0] < 10 ) ? ( "0" . $time[0] ) : $time[0] );
    my $message = '';

    if ( $local{rfc3164} ) {
        $self->{host} ||= inet_ntoa( ( gethostbyname(hostname) )[4] );
        $message = "<$d>$ts $self->{host} $local{Name}$pid: $msg";
    }
    else {
        $message = "<$d>$local{Name}$pid: $msg";
    }

    $self->{Socket} ||= IO::Socket::INET->new(
        PeerAddr => $local{SyslogHost},
        PeerPort => $local{SyslogPort},
        Proto    => 'udp'
    );
    die "Socket could not be created : $!\n" unless $self->{Socket};
    $self->{Socket}->blocking(0);
    return eval{$self->{Socket}->syswrite($message,length($message));};
}
