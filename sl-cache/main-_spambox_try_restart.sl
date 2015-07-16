#line 1 "sub main::_spambox_try_restart"
package main; sub _spambox_try_restart {
    if($AsAService) {
        exec('cmd.exe /C net stop SPAMBOXSMTP & net start SPAMBOXSMTP');
    } elsif ($AsADaemon == 1) {
        exit 1;
    } elsif ($AutoRestartCmd && $AsADaemon == 2) {
        exec($AutoRestartCmd);
    } elsif ($AutoRestartCmd && $AsADaemon == 3) {
        exec($AutoRestartCmd);
        exit 1;
    } elsif (!$AutoRestartCmd && ($AsADaemon == 3 || $AsADaemon == 2)) {
        mlog(0,"error: AutoRestartCmd is not defined in daemon mode $AsADaemon - don't know what to do!");
        mlogWrite();
    } else {
        if ($AutoRestartCmd && $AutoRestart) {
            exec($AutoRestartCmd);
        }
        exit 1;
    }
}
