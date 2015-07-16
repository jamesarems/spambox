#line 1 "sub ASSP::CRYPT::_crypt"
package ASSP::CRYPT; sub _crypt {
	my ($self, $data, $decrypt, $bin) = @_;
    return $data unless $self->{PASS};
	$bin = $bin || $self->{BIN};
    my $l;
    my $check;
    my $cl = $bin ? 3 : 6;
    my $ll = $bin ? 2 : 4;
    if ($decrypt) {
        $check = substr($data,length($data)-$cl,$cl);
        $data = substr($data,0,length($data)-$cl);
        $l = int(hex(_IH(substr($data,length($data)-$ll,$ll),$bin)));
        $data = substr($data,0,length($data)-$ll);
	    $data = _HI($data,! $bin);
	} else {
        $check = _XOR_SYSV($data,$bin);
        $l = length($data);
        my $s = $l % 8;
        $l = _HI(sprintf("%04x",($l % 65536)),$bin);
        $data .= "\x5A" x (8-$s) if $s;
	}
	my ($d1, $d2) = (0,0);
	my $return = '';
    if ($self->{useXS}) {
        for (unpack('(a8)*',$data)) {
            $return .= ($decrypt) ? $self->{useXS}->decrypt($_) : $self->{useXS}->encrypt($_);
        }
    } else {
        my @j =
    		map { $decrypt ? (($_ >  7) ? (31 - $_) % 8 : ($_ % 8))
                           : (($_ > 23) ? (31 - $_)     : ($_ % 8));
    		} (0..31);
        for (unpack('(a8)*',$data)) {
            ($d1,$d2) = unpack 'L2';
            map { ($_ % 2) ? ($d1 ^= _substitute ($self, ($d2 + $self->{KEY}[$j[$_]])))
                           : ($d2 ^= _substitute ($self, ($d1 + $self->{KEY}[$j[$_]])));
    		} (0..31);
    		$return .= pack 'L2', $d2, $d1;
    	}
	}
    return _IH($return,! $bin).$l.$check unless ($decrypt);
    $l += int(length($return)/65536) * 65536 if (length($return) > 65535);
    $return = substr($return,0,$l);
    return if _XOR_SYSV($return,$bin) ne $check;
    return $return;
}
