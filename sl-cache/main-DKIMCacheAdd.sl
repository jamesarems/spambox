#line 1 "sub main::DKIMCacheAdd"
package main; sub DKIMCacheAdd {
    my $domain = lc shift;
    return unless $domain;
    lock($DKIMCacheLock) if $lockDatabases;
    $DKIMCache{$domain} = time;
}
