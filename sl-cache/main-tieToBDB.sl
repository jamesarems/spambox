#line 1 "sub main::tieToBDB"
package main; sub tieToBDB {
    my ($hash,$file,$env) = @_;
    my $Object = $hash . 'Obj';

eval (<<'EOT');
    ${$Object}=tie %$hash,'BerkeleyDB::Hash',
                       (-Filename => "$file",
                        -Flags => DB_CREATE,
                        -Env => $env);
    BDB_filter(${$Object});
EOT
    if ($@ or $BerkeleyDB::Error !~ /: 0\s*$/o) {
        mlog(0,"BerkeleyDB-TIE-ERROR $hash: $@ - BDB:$BerkeleyDB::Error");
        $ComWorker{$WorkerNumber}->{run} = 0 if $WorkerNumber > 0;
        $ComWorker{$WorkerNumber}->{inerror} = 1 if $WorkerNumber > 0;
        die "$@\n";
    }
    BDB_getRecordCount($hash);
}
