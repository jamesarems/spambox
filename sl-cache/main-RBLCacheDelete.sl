#line 1 "sub main::RBLCacheDelete"
package main; sub RBLCacheDelete {
    return if !$RBLCacheExp;
    my $ip = shift;
    return unless ($RBLCacheObject);
    lock($RBLCacheLock) if $lockDatabases;
    delete $RBLCache{$ip};
  }
