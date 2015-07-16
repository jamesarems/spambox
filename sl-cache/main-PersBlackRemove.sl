#line 1 "sub main::PersBlackRemove"
package main; sub PersBlackRemove {
    my ($to, $from) = @_;
    d("PersBlackRemove: $to, $from");
    $to = lc $to;
    $from = lc $from;
    my $i = 0;
    my $pbf;
    while (($pbf = PersBlackFind($to, $from)) && ++$i < 10) {
        d("PersBlackRemove: found = $pbf - record to delete = $to,$pbf");
        delete($PersBlack{"$to,$pbf"}) && $MaintenanceLog &&
           mlog(0,"info: removed personalblack record $to,$pbf");
    }
    $PersBlackHasRecords = getDBCount('PersBlack','persblackdb');
}
