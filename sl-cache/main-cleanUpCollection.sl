#line 1 "sub main::cleanUpCollection"
package main; sub cleanUpCollection {
    d('cleanUpCollection');
    my %ages;
    ($ages{incomingOkMail},$ages{discarded},$ages{viruslog}) = split(/\s+/o, $MaxNoBayesFileAge);
    $ages{discarded} = $ages{incomingOkMail} unless defined $ages{discarded};
    $ages{viruslog} = $ages{incomingOkMail} unless defined $ages{viruslog};
    $ages{incomingOkMail} *= 3600 * 24;
    $ages{discarded} *= 3600 * 24;
    $ages{viruslog} *= 3600 * 24;
    my @dirs = ('incomingOkMail','discarded','viruslog');
    &ThreadMaintMain2() if $WorkerNumber == 10000;
    if ($ages{incomingOkMail} || $ages{discarded} || $ages{viruslog}) {
        mlog(0,"info: starting collection cleanup on NoBayesian folders") if $MaintenanceLog >= 2;
        foreach my $dir (@dirs) {
            &cleanUpFiles(${$dir},'',$ages{$dir}) if ${$dir} && $ages{$dir};
        }
    }
    if ($MaintBayesCollection) {
        &ThreadMaintMain2() if $WorkerNumber == 10000;
        %ages = ();
        ($ages{spamlog},$ages{notspamlog}) = split(/\s+/o, $MaxBayesFileAge);
        $ages{notspamlog} = $ages{spamlog} unless defined $ages{notspamlog};
        $ages{spamlog} *= 3600 * 24;
        $ages{notspamlog} *= 3600 * 24;
        @dirs = ('spamlog','notspamlog');
        mlog(0,"info: starting collection cleanup on Bayesian folders - spamlog and notspamlog") if $MaintenanceLog >= 2;
        foreach my $dir (@dirs) {
            if ($ages{$dir}) {
                &cleanUpFiles(${$dir},'',$ages{$dir}) if ${$dir};
            } else {
                if (! $RunTaskNow{cleanUpMaxFiles}) {
                    $RunTaskNow{cleanUpMaxFiles} = $WorkerNumber;
                    &cleanUpMaxFiles(${$dir},0) if ${$dir};
                    $RunTaskNow{cleanUpMaxFiles} = '';
                }
            }
        }
        &ThreadMaintMain2() if $WorkerNumber == 10000;
        %ages = ();
        ($ages{correctedspam},$ages{correctednotspam}) = split(/\s+/o, $MaxCorrectedDays);
        $ages{correctednotspam} = $ages{correctedspam} unless defined $ages{correctednotspam};
        $ages{correctedspam} *= 3600 * 24;
        $ages{correctednotspam} *= 3600 * 24;
        @dirs = ('correctedspam','correctednotspam');
        mlog(0,"info: starting collection cleanup on Bayesian folders - correctedspam and correctednotspam") if $MaintenanceLog >= 2;
        foreach my $dir (@dirs) {
            if ($ages{$dir}) {
                &cleanUpFiles(${$dir},'',$ages{$dir}) if ${$dir};
            } else {
                if (! $RunTaskNow{cleanUpMaxFiles}) {
                    $RunTaskNow{cleanUpMaxFiles} = $WorkerNumber;
                    &cleanUpMaxFiles(${$dir},0) if ${$dir};
                    $RunTaskNow{cleanUpMaxFiles} = '';
                }
            }
        }
        &fillSpamfiles();
    }
}
