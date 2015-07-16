#line 1 "sub main::scanFile4VirusOK"
package main; sub scanFile4VirusOK {
    my $parm = shift;
    my ($fh, $file);
    if (ref($parm) eq 'ARRAY') {
        ($fh, $file) = @$parm;
    } elsif (ref $parm) {
        return 1;
    } else {
        ($fh, $file) = split(/\s+/o,$parm,2);
    }
    return 1 unless $file;
    return 1 unless $viruslog;
    my $cleanup;
    if (! $fh || ! exists($Con{$fh})) {
        $fh ||= time;
        if (! exists($Con{$fh}) ) {
            $Con{$fh} = {};
            $cleanup = 1;
        }
        $Con{$fh}->{overwritedo} = 1;
        $Con{$fh}->{maillogfilename} ||= $file;
        $Con{$fh}->{headerlength} ||= 10000;
    }
    my $scanForVirus =    (( $ClamAVLogScan && $UseAvClamd && $CanUseAvClamd ) || ( $FileLogScan > 1 && $DoFileScan && $FileScanCMD ))
                       && $Con{$fh}->{maillogfilename} !~ m{^\Q$base\E/\Q$viruslog\E};
    if (! $scanForVirus) {
        delete $Con{$fh}->{overwritedo};
        delete $Con{$fh} if $cleanup;
        return 1;
    }

    my $bytes = max( ($MaxBytes + $Con{$fh}->{headerlength}), ($ClamAVBytes + $Con{$fh}->{headerlength}), 100000);
    my $buf;
    if ($open->(my $mfh,'<',$Con{$fh}->{maillogfilename})) {
        $mfh->binmode;
        my $hasread = 1;
        while ($hasread > 0 and length($buf) < $bytes) {
            my $read;
            $hasread = $mfh->read($read,$bytes);
            $buf .= $read;
        }
        close $mfh;
    } else {
        delete $Con{$fh}->{overwritedo};
        delete $Con{$fh} if $cleanup;
        return 1;
    }

    if ($buf) {
        $Con{$fh}->{scanfile} = de8($Con{$fh}->{maillogfilename});
        if (    ($ClamAVLogScan && $UseAvClamd && $CanUseAvClamd && ! ClamScanOK_Run($fh, bodyWrap(\$buf,length($buf))))
             || ($FileLogScan > 1 && $DoFileScan && $FileScanCMD && ! FileScanOK_Run($fh, bodyWrap(\$buf,length($buf)))) )
        {
            my $vfile = $Con{$fh}->{maillogfilename};
            $vfile =~ s/^\Q$base\E\/[^\/]+/$base\/$viruslog/;
            mlog(($fh =~ /^\d+$/o ? 0 : $fh),'info: moved virus infected file '.$Con{$fh}->{scanfile}.' to '.de8($vfile)) if $move->($Con{$fh}->{maillogfilename},$vfile);
            delete $Con{$fh}->{scanfile};
            delete $Con{$fh}->{overwritedo};
            delete $Con{$fh} if $cleanup;
            return 0;
        }
    }

    delete $Con{$fh}->{scanfile};
    delete $Con{$fh}->{overwritedo};
    delete $Con{$fh} if $cleanup;
    return 1;
}
