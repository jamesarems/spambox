#line 1 "sub main::configUpdateSPAMBOXCfg"
package main; sub configUpdateSPAMBOXCfg {
    my ($name, $old, $new, $init)=@_;
    if (fileUpdated("spambox.cfg",$name)){
        if ($WorkerNumber == 0) {
            mlog(0,"AdminUpdate: spambox.cfg was externally changed - reload the configuration");
            &reloadConfigFile();
            $ConfigChanged = 0;
        }
        $asspCFGTime = $FileUpdate{"$base/spambox.cfg$name"} = ftime("$base/spambox.cfg");
    }
    return;
}
