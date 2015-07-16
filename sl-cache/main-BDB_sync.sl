#line 1 "sub main::BDB_sync"
package main; sub BDB_sync {
    d('BDB_sync');
    my $timeout = shift;
    $timeout = 0 unless $timeout;
    if ($DoSyncBDB) {
        mlog(0,'info: synchronizing all BerkeleyDB hashes to disk') if $MaintenanceLog;
        foreach (keys %BerkeleyDBHashes) {
            d("BDB_sync - $_");
            my $res = &BDB_sync_hash($_);
        }
        mlogWrite() if $WorkerName eq 'Shutdown';
    }
    if ($DoCompactBDB && $WorkerName ne 'Shutdown') {
        mlog(0,'info: compacting all BerkeleyDB hashes on disk') if $MaintenanceLog;
        foreach (keys %BerkeleyDBHashes) {
            d("BDB_compact - $_");
            my $res = BDB_compact_hash($_,$timeout);
        }
    }
    return 1;
}
