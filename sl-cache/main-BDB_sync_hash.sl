#line 1 "sub main::BDB_sync_hash"
package main; sub BDB_sync_hash {
    my $hash = shift;
    return 0 unless $hash;
    return 0 unless $DoSyncBDB;
    return 0 unless tied %{$hash};
    my $dbo = $hash . 'Object';     # main hashes
    $dbo = $hash . 'Obj' unless defined ${$dbo};   # temp hashes
    return 0 unless defined ${$dbo};
    my $res;
    if ("$$dbo" =~ /spambox::/io) {
        eval{
             my $lock;
             $lock = ${$dbo}->{hashobj}->cds_lock() if $main::lockBDB && ${$dbo}->{hashobj}->cds_enabled();
             $res = ${$dbo}->{hashobj}->db_sync();
        };
    } else {
        eval{
             my $lock;
             $lock = ${$dbo}->cds_lock() if $main::lockBDB && ${$dbo}->cds_enabled();
             $res = ${$dbo}->db_sync();
        };
    }
    if ($@ or ($res != 0 && $BerkeleyDB::error)) {
        mlog(0,"warning: unable to write cache of BerkeleyDB hash $hash to disk - $@ - BDB:$BerkeleyDB::error");
        return 0;
    } else {
        mlog(0,"info: synchronized BerkeleyDB hash $hash to disk") if $MaintenanceLog >= 2 && $dbo !~ /Obj$/o;
    }
    return 1;
}
