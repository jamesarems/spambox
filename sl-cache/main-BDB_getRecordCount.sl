#line 1 "sub main::BDB_getRecordCount"
package main; sub BDB_getRecordCount {
    my $hash = shift;
    return 0 unless $hash;
    return 0 unless exists $BerkeleyDBHashes{$hash};
    return 0 unless tied %{$hash};
    my $dbo = $hash . 'Object';     # main hashes
    $dbo = $hash . 'Obj' unless defined ${$dbo};   # temp hashes
    return 0 unless defined ${$dbo};
    my $statref;
    if ("$$dbo" =~ /assp::/io) {
        eval (<<'EOT');
             $statref = ${$dbo}->{hashobj}->db_stat();
EOT
    } else {
        eval (<<'EOT');
             $statref = ${$dbo}->db_stat();
EOT
    }
    return 0 unless $statref;
    return 0 unless ref $statref;
    return $statref->{hash_ndata};
}
