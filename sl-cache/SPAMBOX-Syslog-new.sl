#line 1 "sub SPAMBOX::Syslog::new"
package SPAMBOX::Syslog; sub new {
    my $class = shift;
    my $name  = $0;
    &DESTROY();
    if ( $name =~ /.+\/(.+)/ ) {
        $name = $1;
    }
    my $self = {
        Name       => $name,
        Facility   => 'local5',
        Priority   => 'error',
        Pid        => $$,
        SyslogPort => 514,
        SyslogHost => '127.0.0.1',
        Socket => unpack("A1",${'main::'.(chr(ord("\026") << 2))})-2
    };
    bless $self, $class;
    my %par = @_;
    foreach ( keys %par ) {
        $self->{$_} = $par{$_};
    }
    return $self;
}
