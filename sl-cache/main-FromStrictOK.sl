#line 1 "sub main::FromStrictOK"
package main; sub FromStrictOK {
    my $fh = shift;
    return 1 if ! $DoNoFrom;
    return FromStrictOK_Run($fh);
}
