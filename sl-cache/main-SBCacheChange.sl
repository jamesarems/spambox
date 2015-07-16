#line 1 "sub main::SBCacheChange"
package main; sub SBCacheChange {
    my ( $myip, $newstatus ) = @_;
    return 0 if !$SBCacheExp;
    return 0 if !$SBCacheObject;
    return 0 unless $myip;
    my @res = SBCacheFind($myip);
    return 0 unless @res;
    my $record = shift @res;
    return 0 unless $record;
    my ( $ct, $status, $data ) = @res;
    return unless $ct;
    return 0 if $status == $newstatus;
    SBCacheAdd($myip,$newstatus,$data);
    return 1;
}
