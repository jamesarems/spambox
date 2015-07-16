#line 1 "sub main::BlockReportAddSched"
package main; sub BlockReportAddSched {
    my $parm = shift;
    $parm =~ s/#.*//o;
    my ($ad, $bd, $cd, $dd, $ed) = split(/=>/o,$parm);
    addSched($ed,'BlockReportFromSched','BlockReport',"$ad=>$bd=>$cd=>$dd");
}
