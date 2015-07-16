#line 1 "sub main::uploadGlobalPB"
package main; sub uploadGlobalPB {
    my $list = shift;
    my $time = time;
    my $longRetry = $time + (int(rand(300) + 1440)*60 );
    my $shortRetry  = $time + ( ( int( rand(120) ) + 60 ) * 60 );
    my $nextGlobalUpload;
    d("uploadGlobalPB - $list");
    
    if ($list eq 'pbdb.black.db') {
          $nextGlobalUpload = 'nextGlobalUploadBlack';
    } else {
          $nextGlobalUpload = 'nextGlobalUploadWhite';
    }

    $$nextGlobalUpload = $longRetry;

    if ( !$CanUseLWP ) {
        mlog( 0, "ConfigError: global-PB $list Update failed: LWP::Simple Perl module not available" );
        return 0;
    }
    if ( !$CanUseHTTPCompression ) {
        mlog( 0, "ConfigError: global PB $list Update failed: Compress::Zlib Perl module not available" );
        return 0;
    }

    my $outfile = "$base/$pbdir/global/out/$list";
    my $outfilez = "$base/$pbdir/global/out/$list.gz";
    my $infilez = "$base/$pbdir/global/in/$list.gz";
    my $infile = "$base/$pbdir/global/in/$list.db";
    if ($list eq 'pbdb.black.db') {
          return 0 unless &genGlobalPBBlack();
    } else {
          return 0 unless &genGlobalPBWhite();
    }
    &zipgz($outfile,$outfilez) or return 0;
    if (&sendGlobalFile($list,$outfilez,$infilez)) {
       $$nextGlobalUpload = $longRetry;
    } else {
       $$nextGlobalUpload = $shortRetry;
       return 0;
    }
    my $m = &getTimeDiff($$nextGlobalUpload - $time);
    mlog(0,"info: next $list upload to global server is scheduled in $m") if ($MaintenanceLog);
    return 0 if (! -e "$infilez");
    unlink("$infile");
    &unzipgz("$infilez","$infile") or return 0;
    return 0 if (! -e "$infile");
    return 1 if $mysqlSlaveMode;
    return 1 if ($list eq 'pbdb.black.db' && ! $DoGlobalBlack);
    return 1 if ($list eq 'pbdb.white.db' && ! $DoGlobalWhite);
    mlog(0,"info: merging global-PB $list in to local-PB") if $MaintenanceLog;
    my $count = 0;
    my $fcount = 0;
    my $GPB;
    open $GPB,'<' ,"$infile";
    if ($list eq 'pbdb.black.db') {
        while (<$GPB>) {
            $fcount++;
            if ($fcount%1000 == 0) {
                threads->yield();
                $lastd{10000} = "merging global-PB $list - read $fcount ,added $count records";
                &ThreadMaintMain2() if $WorkerNumber == 10000;
            }
            my ($k,$v) = split/\002/o;
            chomp $v;
            next unless ($k && $v);
            next if (exists $PBWhite{$k});
            my $pbb;
            next if (($pbb = $PBBlack{$k}) && $pbb !~ /GLOBALPB$/o);
            next if &matchIP($k,'noPB',0,1);
            next if &matchIP($k,'ispip',0,1);
            my($tc,$tu,$cu,$val,$ip,$reason) = split(/ /o,$v);
            $val = ${'globalValencePB'}[0] if(${'globalValencePB'}[0] >= 0);
            $v = "$tc $tu $cu $val $ip $reason";
            $PBBlack{$k} = $v;
            $count++;
            last if(! $ComWorker{$WorkerNumber}->{run});
        }
        if ($count) {
            mlog(0,"saving penalty Black records") if $MaintenanceLog;
            &SaveHash('PBBlack');
        }
    } else {
        while (<$GPB>) {
            $fcount++;
            if ($fcount%1000 == 0) {
                threads->yield();
                $lastd{10000} = "merging global-PB $list - read $fcount ,added $count records";
                &ThreadMaintMain2() if $WorkerNumber == 10000;
            }
            my ($k,$v) = split/\002/o;
            chomp $v;
            my $pbw;
            next if (($pbw = $PBWhite{$k}) && $pbw !~ /GLOBALPB$/o);
            next if &matchIP($k,'noPBwhite',0,1);
            my($tc,$tu,$cu) = split(/ /o,$v);
            $cu = 3;
            $v = "$tc $tu $cu GLOBALPB";
            $PBWhite{$k} = $v;
            delete $PBBlack{$k};
            $count++;
            last if(! $ComWorker{$WorkerNumber}->{run});
        }
        if ($count) {
            mlog(0,"saving penalty White records") if $MaintenanceLog;
            &SaveHash('PBWhite');
        }
    }
    close $GPB;
    mlog(0,"info: $count records merged from global-PB $list in to local-PB") if $MaintenanceLog;
    return 1;
}
