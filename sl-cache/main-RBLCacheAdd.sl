#line 1 "sub main::RBLCacheAdd"
package main; sub RBLCacheAdd {
    my ( $ip, $status, $rbllists) = @_;
    return if $ip =~ /$IPprivate/o;
    my $t = time;
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
    $mon++;
    $year += 1900;
    my $mm = sprintf( "%04d-%02d-%02d/%02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec );
    my $data = "$t $mm $status $rbllists";
    lock($RBLCacheLock) if $lockDatabases;
    $RBLCache{$ip} = $data;
}
