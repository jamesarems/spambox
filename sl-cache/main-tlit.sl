#line 1 "sub main::tlit"
package main; sub tlit {
    my $mode = shift;

    return '[monitoring]' if $mode == 2;
    return '[scoring]'    if $mode == 3;
    return '[testmode]'   if $mode == 4;
}
