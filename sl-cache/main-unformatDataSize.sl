#line 1 "sub main::unformatDataSize"
package main; sub unformatDataSize {
    my ($size,$default)=@_;
    my @a=split(/\s+/o,$size);
    my $res=0;
    while (@a) {
        my $j = shift @a;
        my ($s,$mult)=$j=~/^(.*?) ?(B|kB|MB|GB|TB)?$/oi;
        $mult||=$default||'B'; # default to bytes
        $mult = lc($mult);
        if ($mult eq 'b') {
            $res+=$s;
        } elsif ($mult eq 'kb') {
            $res+=$s*1024;
        } elsif ($mult eq 'mb') {
            $res+=$s*1048576;
        } elsif ($mult eq 'gb') {
            $res+=$s*1073741824;
        } elsif ($mult eq 'tb') {
            $res+=$s*1099511627776;
        }
    }
    return $res;
}
