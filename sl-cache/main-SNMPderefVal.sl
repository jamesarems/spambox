#line 1 "sub main::SNMPderefVal"
package main; sub SNMPderefVal {
    my $val = shift;
    return $val unless ref $val;
    return $$val if $val =~ /SCALAR/o;
    my @vars = @{$val};
    my $call = shift @vars;
    foreach (@vars) {
       $_ = SNMPderefVal($_);
    }
    return $call->(@vars);
}
