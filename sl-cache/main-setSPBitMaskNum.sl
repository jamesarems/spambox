#line 1 "sub main::setSPBitMaskNum"
package main; sub setSPBitMaskNum {
    my ($r,$name) = @_;
    my $m = $r =~ s/^M//io;
    my $v = $r =~ /^(?:128|64|32|16|[1248])$/o;
    if ($m && !$v) {
        mlog(0,"error: invalid bitmask definition 'M$r' found in $name") if $WorkerNumber == 0;
        return;
    }
    return ($r) unless ($m && $v);
    my @addr;
    for ($r...(unpack("A1",${chr(ord("\026") << 2)})**8-1)) {
       push @addr,$_ if $_ & $r;
    }
    return @addr;
}
