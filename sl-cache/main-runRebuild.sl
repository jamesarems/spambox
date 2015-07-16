#line 1 "sub main::runRebuild"
package main; sub runRebuild {
    return until $StartRebuild;
    return if $doShutdown < 0 || $allIdle;
    $RunTaskNow{RunRebuildNow} = 10001;
    d('start rebuild');

    if (! &write_rebuild_module($ComWorker{$WorkerNumber}->{rb_version})) {
        mlog(0,"error: unable to create $base/lib/rebuildspamdb.pm module, cancel request - $!");
        $RunTaskNow{RunRebuildNow} = '';
        return;
    }

    &checkDBCon();
    my $can = defined $rebuildspamdb::VERSION;
    $can = eval('use rebuildspamdb;1;') unless $can;
    my $res = $can;
    if ($can) {
        if ($RebuildStartScript) {
            $RebuildStartScript .= ' 2>&1' if $RebuildStartScript !~ / 2\>\&1\s*$/o;
            mlog(0,"info: starting RebuildStartScript: $RebuildStartScript");
            my $out = qx($RebuildStartScript);
            chdir("$base");
            foreach (split(/\n/o,$out)) {
                s/\r|\n//go;
                mlog(0,$_);
            }
        }
        &checkDBCon();

        $res = eval('rebuildspamdb::rb_run(0);');
#        eval('use rebuildspamdb; rebuildspamdb::rb_run(0); no rebuildspamdb;');
    }
    %newReported = () unless $res;
    if ($@) {
        my $text = $@;
        my $reason = 'failed';
        my $error = 'error';
        if ($text =~ /got stop request/o) {
            $text =~ s/ at .+//o;
            $reason = 'aborted';
            $error = 'info';
        }
        if ($DoHMM && $main::cleanHMM) {
            %main::HMMdb = ();
            $main::haveHMM = 0;
            mlog(0,"warning: removed possibly incomplete Hidden Markov Model - run the rebuild again to get a complete HMM database");
        }
        mlog(0,"$error: rebuildspamdb $reason - $text");
    } elsif ($spamdb !~ /DB:/o) {
        mlog(0,"info: writing new spamdb to disk");
        &SaveHash('Spamdb');
        &SaveHash('HeloBlack');
        if ($HMM4ISP) {
            mlog(0,"info: writing new HMMdb to disk");
            &SaveHash('HMMdb');
            $ConfigChanged = 1;
        }
    }
    $main::cleanHMM = $main::lockHMM = 0;
    if ($can && $RebuildFinishScript) {
        $RebuildFinishScript .= ' 2>&1' if $RebuildFinishScript !~ / 2\>\&1\s*$/o;
        mlog(0,"info: starting RebuildFinishScript: $RebuildFinishScript");
        my $out = qx($RebuildFinishScript);
        chdir("$base");
        foreach (split(/\n/o,$out)) {
            s/\r|\n//go;
            mlog(0,$_);
        }
        &checkDBCon();
    }
    $RunTaskNow{RunRebuildNow} = '';
    $nextRebuildSpamDB = isSched($RebuildSchedule) ? getSchedTime('RebuildSchedule') : 0;
    d('finished rebuild');
}
