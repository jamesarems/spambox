#line 1 "sub main::initPrivatHashes"
package main; sub initPrivatHashes {
    my $clean = shift;
    if ($griplist && ! $GriplistObj) {
        if ($GriplistDriver eq 'BerkeleyDB::Hash' && $useDB4griplist) {
            my $file = "$base/$griplist";
            d("BDB-DB (initPrivatHashes) - Griplist , $file.bdb");
            &tieToBDB('Griplist', "$file.bdb", &createBDBEnv('Griplist'));
        } else {
            $GriplistObj=tie %Griplist,$GriplistDriver,$GriplistFile;
            $GriplistObj->resetCache();
            my $r = loadHashFromFile("$base/$griplist", $GriplistObj->{cache}) || 'no';
#            mlog(0,"info: Griplist has $r records") if $MaintenanceLog >= 2;
            $GriplistObj->{max} = 999999999999;
            $GriplistObj->{bin} = 0;
        }
    }

    if ($CanUseBerkeleyDB && $runHMMusesBDB && exists $tempDBvars{'HMMdb'}) {
        my $hash = 'HMMdb';
        my $file = "$base/$hash.bdb" ;
        my %userenv = ('-Cachesize' => 10 * 1024 * 1024) ;
        d("BDB-DB (initPrivatHashes) - $hash , $file");
        &tieToBDB($hash,
                  $file,
                  &createBDBEnv($hash,\%userenv)
                 ) unless tied(%{$hash});
        mlog(0,"info: HMMdb is using 'BerkeleyDB' version $BerkeleyDB::db_version in file $base/$hash.bdb, because HMMusesBDB is set to ON") if $WorkerNumber == 0;
    }
    
    if ($CanUseBerkeleyDB && $useDB4IntCache) {
        my ($BackDNS2DB) = $localBackDNSFile =~ /^ *file: *(.+)/io;
        $BackDNS2DB = "$base/tmpDB/BackDNS2/BackDNS2.bdb" if $BackDNS2DB ;

        mlog(0,"info: internal hashes are using 'BerkeleyDB' version $BerkeleyDB::db_version in directory $base/tmpDB") if $WorkerNumber == 0;

        foreach (sort keys %tempDBvars) {
            next if $_ eq 'BackDNS2';
            next if $_ =~ /^HMM/oi;
#            next if $WorkerNumber == 10001;
            my $file = "$base/tmpDB/$_/$_.bdb";
            my %userenv = ();
            d("BDB-DB (initPrivatHashes) - $_ , $file");
            &tieToBDB($_,
                      $file,
                      &createBDBEnv($_,\%userenv)
                     ) unless tied(%{$_});
            %{$_} = ()
                if (   $_ ne 'Stats'
                    && $_ ne 'ScoreStats'
                    && $_ ne 'WhiteOrgList'
                    && $_ ne 'DMARCpol'
                    && $_ ne 'DMARCrec'
                    && $_ ne 'subjectFrequencyCache'
                    && $clean
                    && $WorkerNumber == 0);
        }

        if (! tied(%BackDNS2) &&
                       $BackDNS2DB &&
                       ($DBusedDriver ne 'BerkeleyDB' or
                        ($DBusedDriver eq 'BerkeleyDB' && $pbdb !~ /DB:/io)
                       )
                      )
        {
            d("BDB-DB (initPrivatHashes) - BackDNS2 , $BackDNS2DB");
            &tieToBDB('BackDNS2',
                      $BackDNS2DB,
                      &createBDBEnv('BackDNS2')
                     );
        }
    }
}
