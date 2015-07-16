#line 1 "sub main::MXACacheAdd"
package main; sub MXACacheAdd {
    my ( $mydomain, $mxrecord, $arecord ) = @_;
    return 0 if !$MXACacheInterval;
    return 0 unless ($MXACacheObject);
    lock($MXACacheLock) if $lockDatabases;
    $MXACache{lc $mydomain} = time . " $mxrecord $arecord";
}
