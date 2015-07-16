#line 1 "sub main::BDB_compact_hash"
package main; sub BDB_compact_hash {
    my ($hash , $timeout) = @_;
    return 0 unless $hash;
    return 0 unless tied %{$hash};
    my $dbo = $hash . 'Object';     # main hashes
    $dbo = $hash . 'Obj' unless defined ${$dbo};   # temp hashes
    return 0 unless defined ${$dbo};
    my $res;

    return 1 unless (($WorkerNumber == 10000 and $BerkeleyDBHashes{$hash} > time) or $WorkerNumber == 0);
    $BerkeleyDBHashes{$hash} = time + 3600;

    my $bdbf = getHashBDBName($hash);
    my %hash;
    $hash{compact_fillpercent} = 10;
    $timeout *= 1000000;
    $timeout ||= 1000000; # 1 second
    $hash{compact_timeout} = $timeout;

    if ("$$dbo" =~ /assp::/io) {
        eval (<<'EOT');
             my $lock;
             $lock = ${$dbo}->{hashobj}->cds_lock() if $main::lockBDB && ${$dbo}->{hashobj}->cds_enabled();
             $res = ${$dbo}->{hashobj}->compact(undef,
                                                undef,
                                                \%hash,
                                                DB_FREE_SPACE
                                               );
EOT
    } else {
        eval (<<'EOT');
             my $lock;
             $lock = ${$dbo}->cds_lock() if $main::lockBDB && ${$dbo}->cds_enabled();
             $res = ${$dbo}->compact(undef,
                                     undef,
                                     \%hash,
                                     DB_FREE_SPACE
                                    );
EOT
    }
    if ($@ or ($res != 0 && $BerkeleyDB::error)) {
        mlog(0,"warning: unable to compact file $base/$bdbf.bdb of BerkeleyDB hash $hash - $@ - BDB:$BerkeleyDB::error");
        return 0;
    } else {
        my $ext;
        if ($MaintenanceLog > 2 && $dbo !~ /Obj$/o && keys %hash) {
            $ext = ' [';
            foreach (keys %hash) {
                $ext .= "$_: $hash{$_}, ";
            }
            $ext =~ s/, $//o;
            $ext .= ']';
        }
        mlog(0,"info: done compact file $base/$bdbf.bdb of BerkeleyDB hash $hash$ext")
            if $MaintenanceLog >= 2 && $dbo !~ /Obj$/o;
        return 1;
    }
}
