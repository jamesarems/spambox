#line 1 "sub ASSP::CRYPT::new"
package ASSP::CRYPT; sub new {
    my ($argument,$pass,$bin,$enh) = @_;
	my $class = ref ($argument) || $argument;
	my $self = {};
    &DESTROY();
    use bytes;
    {
        local $SIG{__WARN__} = sub {1};
        $self->{useXS} = (defined($enh) ? $enh : ($main::usedCrypt > 0)) && $pass && eval('use Crypt::GOST();1;');
    }
    $self->{KEY} = [];
	$self->{SBOX} = [];
	$self->{BIN} = $bin;
    if ($self->{useXS}) {
        $pass .= $pass x int(32 / length($pass) + 1);
        $pass = substr($pass , 0, 32);
        $self->{useXS} = Crypt::GOST->new($pass);
    }
    $self->{PASS} = $pass;
    if (! $self->{useXS} && $pass) {
        _generate_sbox($self,$pass);
        _generate_keys($self,$pass);
    }
    bless $self, $class;
    return $self;
}
