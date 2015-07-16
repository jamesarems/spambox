#line 1 "sub main::pbWhiteDelete"
package main; sub pbWhiteDelete {
    my($fh,$myip)=@_;
    $Con{$fh}->{rwlok}=0 if $fh;
    return if !$DoPenalty;

    my $ip=&ipNetwork($myip,$PenaltyUseNetblocks);
    lock($PBWhiteLock) if $lockDatabases;
    delete $PBWhite{$myip};
    if ($ip ne $myip) {
        delete $PBWhite{$ip};
    }
}
