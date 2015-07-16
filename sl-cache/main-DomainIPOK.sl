#line 1 "sub main::DomainIPOK"
package main; sub DomainIPOK {
    my $fh = shift;
    return 1 if ! $DoDomainIP;
    return DomainIPOK_Run($fh);
}
