#line 1 "sub main::MaillogClose"
package main; sub MaillogClose {
    my $fh = shift;
    d('MaillogClose');
    return unless $fh;
    my $f=$Con{$fh}->{maillogfh};
    eval{$f->close if $f;};
    return if $Con{$fh}->{type} ne 'C';
    return unless $Con{$fh}->{maillogfilename};

    my $handles = 0;
    if ($WorkerNumber < 10000) {
        eval { $handles += $readable->handles() if defined $readable;
               $handles += $writable->handles() if defined $writable;
        };
    }
    
    my $scanForVirus =    ! $Con{$fh}->{averror}
                       && (( $ClamAVLogScan && $UseAvClamd && $CanUseAvClamd ) || ( $FileLogScan > 1 && $DoFileScan && $FileScanCMD ))
                       && $Con{$fh}->{maillogfilename} !~ m{^\Q$base\E/\Q$viruslog\E};
    if ($Con{$fh}->{deleteMailLog}) {
        $unlink->($Con{$fh}->{maillogfilename});
        mlog($fh,"info: file ".de8($Con{$fh}->{maillogfilename})." was deleted - reason: $Con{$fh}->{deleteMailLog}");
        delete $Con{$fh}->{maillogfilename};
        $scanForVirus = undef;
    } elsif ( $noCollectRe ) {
        my $buf;
        my $bytes = min(($MaxBytes + $Con{$fh}->{headerlength}), 100000);
        if ($open->(my $mfh,'<',$Con{$fh}->{maillogfilename})) {
            $mfh->binmode;
            my $hasread = 1;
            while ($hasread > 0 and length($buf) < $bytes) {
                my $read;
                $hasread = $mfh->read($read,$bytes);
                $buf .= $read;
            }
            $mfh->close;
            if ($buf && $buf =~ /$noCollectReRE/is) {
                if (exists $runOnMaillogClose{'ASSP_ARC::setvars'}) {
                    $Con{$fh}->{deletemaillog} = 'content matches noCollectRe';
                } else {
                    $unlink->($Con{$fh}->{maillogfilename});
                    mlog($fh,"info: file ".de8($Con{$fh}->{maillogfilename})." was deleted - matched noCollectRe");
                    delete $Con{$fh}->{maillogfilename};
                }
            }
        }
    }

# scan for virus here
    if ($scanForVirus && $viruslog && $Con{$fh}->{maillogfilename}) {
        if ($handles <= $WorkerScanConLimit) {
             delete $Con{$fh}->{maillogfilename} unless scanFile4VirusOK([$fh,$Con{$fh}->{maillogfilename}]);
        } else {
            # move the scan to the high threads, if there are other connections to handle
            cmdToThread('scanFile4VirusOK', "0 $Con{$fh}->{maillogfilename}");
        }
    }
    
# run registered routines
    foreach my $sub (keys %runOnMaillogClose) {
        $sub->($fh);
    }
}
