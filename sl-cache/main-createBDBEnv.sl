#line 1 "sub main::createBDBEnv"
package main; sub createBDBEnv {
    my ($hash, $userenv) = @_;
    return unless $hash;

    my $env;
    my $bdbf;
    my %userenv = $userenv ? %$userenv : () ;
    $userenv{'-Cachesize'} = 512 * 1024 if $userenv{'-Cachesize'} < 512 * 1024;
    my $bdbdir = "$base/tmpDB/$hash";

  {
    lock($BDBEnvLock) if is_shared($BDBEnvLock);

    -d "$bdbdir" or mkdir "$bdbdir",0755;

    if ($NumComWorkers <= 7 && ($bdbf = getHashBDBName($hash))) {
        my $size =  -s "$base/$bdbf.bdb";
        $userenv{'-Cachesize'} = $size if ($bdbf && $size > $userenv{'-Cachesize'});
        foreach ( Glob("$base/tmpDB/$hash/*")) {
            if ($_ =~ /\.bdb$/o) {
               $size = -s "$_";
               $userenv{'-Cachesize'} = $size if ($size > $userenv{'-Cachesize'});
            }
        }
    }
    if ($hash =~ /hmm/io) {
        $userenv{'-Cachesize'} = min($BDBMaxCacheSize,$userenv{'-Cachesize'},100*1024*1024);
    } else {
        $userenv{'-Cachesize'} = min($userenv{'-Cachesize'},10*1024*1024); # max 10MB
    }
    $bdbf ||= "tmpDB/$hash/$hash";

eval (<<'EOT');
    $env = BerkeleyDB::Env->new(-Flags => DB_INIT_CDB | DB_INIT_MPOOL | DB_CREATE ,
                                -LockDetect => DB_LOCK_DEFAULT,
                                -Home => "$bdbdir",
                                -ErrFile => "$bdbdir/BDB-error.txt" ,
                                -Config => {DB_DATA_DIR => "$bdbdir",
                                            DB_LOG_DIR  => "$bdbdir",
                                            DB_TMP_DIR  => "$bdbdir"
                                           },
                                 %userenv
                               );
    mlog(0,"BerkeleyDB-CRT-ENV-ERROR (1) in HASH $hash , on file $base/$bdbf.bdb : BDB:$BerkeleyDB::Error")
        if ($BerkeleyDB::Error !~ /: 0\s*$/o);

    if ($WorkerNumber == 10000 && $BerkeleyDB::Error =~ /DB_RUNRECOVERY|Bad file descriptor/oi) {
        undef $env;
        mlog(0,"info: try BDB-Env recovery for hash $hash");
        unlink "$bdbdir/__db.001";
        unlink "$bdbdir/__db.002";
        unlink "$bdbdir/__db.003";
        unlink "$bdbdir/__db.004";
        unlink "$bdbdir/$hash.bdb";

        if ($hash eq 'Griplist') {
            unlink "$base/griplist";
            unlink "$base/griplist.bin";
            unlink "$base/griplist.delta";
            unlink "$base/griplist.bdb";
            $NextGriplistDownload = 0;
            mlog(0,"warning: removed all files for hash $hash to recover from corruption with new download");
        } elsif ($hash eq 'BackDNS2') {
            my ($file) = $localBackDNSFile =~ /^ *file: *(.+)/io;
            if ($file) {
                unlink "$base/$file.txt";
                unlink "$base/$file.gz";
                $NextBackDNSFileDownload = 0;
                mlog(0,"warning: removed all files for hash $hash to recover from corruption with new download");
            }
        } else {
            my $hashfile = getHashBDBName($hash);
            if (-e "$base/$hashfile.bdb") {
                my $todel = $hashfile;
                $hashfile = "/$hashfile" if $hashfile !~ /\//o;
                ($hashfile) = $hashfile =~ /^.*\/([^\/]+)$/o;
                my $src="$base/$backupDBDir/$hashfile";
                my $tar="$base/$importDBDir/$hashfile.rpl";
                if (copy($src,$tar)) {
                    unlink "$base/$todel.bdb";
                    mlog(0,"info: recover corrupt BerkeleyDB for hash $hash from last backup");
                    $RunTaskNow{ImportMysqlDB} = 10000;
                } else {
                    mlog(0,"warning: unable to recover corrupt BerkeleyDB hash from last backup - unable to copy $base/$backupDBDir/$hashfile to $base/$importDBDir/$hashfile.rpl - $!");
                }
            }
        }
        
        $env = BerkeleyDB::Env->new(-Flags => DB_INIT_CDB | DB_INIT_MPOOL | DB_CREATE ,
                                    -LockDetect => DB_LOCK_DEFAULT,
                                    -Home => "$bdbdir",
                                    -ErrFile => "$bdbdir/BDB-error.txt" ,
                                    -Config => {DB_DATA_DIR => "$bdbdir",
                                               DB_LOG_DIR  => "$bdbdir",
                                                DB_TMP_DIR  => "$bdbdir"
                                               },
                                     %userenv
                                   );
        mlog(0,"BerkeleyDB-CRT-ENV-ERROR (2) in HASH $hash , on file $base/$bdbf.bdb : BDB:$BerkeleyDB::Error")
            if ($BerkeleyDB::Error !~ /: 0\s*$/o);


        if ($BerkeleyDB::Error =~ /DB_RUNRECOVERY|Bad file descriptor/oi) {
            $ConfigAdd{clearBerkeleyDBEnv} = 1;
            if ($WorkerNumber == 0) {
                SaveConfig();
            } else {
                $ConfigChanged = 1;
            }
            mlog(0,"error: BerkeleyDB for hash $hash ($base/$bdbf.bdb) needs to be recovered - recovery will be done at next start - try to restart spambox now");
            mlogWrite() if $WorkerNumber == 0;
            $doShutdown = time + 15;
            die "BDB for $hash needs recovery\n";
        }
    }
    $env->set_timeout(1000000,DB_SET_LOCK_TIMEOUT) if $env;
EOT
  }
    if ($@ || $BerkeleyDB::Error !~ /: 0\s*$/o || ! $env) {
         mlog(0,"BerkeleyDB-ENV-ERROR $hash: $@ - BDB:$BerkeleyDB::Error");
         $ComWorker{$WorkerNumber}->{run} = 0 if $WorkerNumber > 0;
         $ComWorker{$WorkerNumber}->{inerror} = 1 if $WorkerNumber > 0;
         delete $BerkeleyDBHashes{$hash};
         die "BerkeleyDB-ENV-ERROR $hash: $@ - BDB:$BerkeleyDB::Error\n" if $WorkerNumber > 0 || ! $doShutdown;
    } else {
         my $bcache =  &formatDataSize(-s "$base/tmpDB/$hash/__db.003",1);
         mlog(0,"info: list $hash is using 'BerkeleyDB' version $BerkeleyDB::db_version - cachesize is $bcache") if $WorkerNumber == 0;
         $BerkeleyDBHashes{$hash} = time;
    }
    return $env;
}
