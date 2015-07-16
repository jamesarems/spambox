#line 1 "sub main::pbTrapDelete"
package main; sub pbTrapDelete {
    my $address = shift;
    lock($PBTrapLock) if $lockDatabases;
    delete $PBTrap{lc $address};
}
