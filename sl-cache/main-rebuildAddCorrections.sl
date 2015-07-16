#line 1 "sub main::rebuildAddCorrections"
package main; sub rebuildAddCorrections {
    return if $doShutdown < 0 || $allIdle;

    if (! $spamdb || (! $haveHMM && ! $haveSpamdb)) {
        %newReported = ();
        return;
    }
    d('start rebuildAddCorrections');
    mlog(0,'start rebuildAddCorrections');

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

        $res = eval('rebuildspamdb::rb_run(1);');
#        eval('use rebuildspamdb; rebuildspamdb::rb_run(1); no rebuildspamdb;');
    }
    %newReported = () unless $res;
    if ($@) {
        %newReported = ();
        my $text = $@;
        my $reason = 'failed';
        my $error = 'error';
        if ($text =~ /got stop request/o) {
            $text =~ s/ at .+//o;
            $reason = 'aborted';
            $error = 'info';
        }
        mlog(0,"$error: rebuildAddCorrections $reason - $text");
    } elsif ($spamdb !~ /DB:/o && $res) {
        mlog(0,"info: writing new spamdb to disk");
        &SaveHash('Spamdb');
        &SaveHash('HeloBlack');
        if ($HMM4ISP) {
            mlog(0,"info: writing new HMMdb to disk");
            &SaveHash('HMMdb');
            $ConfigChanged = 1;
        }
    }
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
    &ThreadYield();
    d('finished rebuildAddCorrections');
    return;
}
