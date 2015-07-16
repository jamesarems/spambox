#line 1 "sub main::nN"
package main; sub nN {
    local $_ = shift;
    my $sep = $LogDateLang ? '.' : ',';
    1 while s/^([-+]?\d+)(\d{3})/$1$sep$2/o;
    return $_;
}
