#line 1 "sub main::loadPluginConfig"
package main; sub loadPluginConfig {
  my $plobj;
  my @plconfig;
  my $plinput;
  my $ploutput;
  my $cmd;
  my $tmp;
  my $version;
  if ($useAsspSelfLoader) {
      &haveToFileScan(0);
      &haveToScan(0);
      &CheckAttachments(0,0,0,0,0); # predefine the sub - repointed in AFC Plugin
  }
  my @runlevel = ('\'SMTP-handshake\'','\'mail header\'','\'complete mail\'');
  -d "$base/Plugins" or return;
  push (@INC,"$base/Plugins") unless grep(/^\Q$base\E\/Plugins$/,@INC);
  opendir(my $DIR,"$base/Plugins");
  my @pllist = readdir($DIR);
  close $DIR;
  foreach my $pl (@pllist) {
    if ($pl =~ /^(assp_(?:wordstem|fc|svg)\.pm)$/io) {
        mlog(0,"warning: $1 is not a Plugin - please move it from '$base/Plugins/$1' to '$base/lib/$1' !");
        next;
    }
    next if ($pl !~ /^(assp_.+)\.pm$/io);
    $pl = $1;
    mlog(0,"Info: try loading plugin $pl");
    $cmd = "unless (eval{$pl->VERSION;}) {use $pl;}";
    eval($cmd);
    if ($@) {
      mlog(0,"error loading plugin (2) $pl (use) - error: $@");
      $cmd = "no $pl";
      eval($cmd);
      next;
    }
    eval{$plobj = $pl->new()};
    if ($@) {
      mlog(0,"error loading plugin $pl (new) - error: $@");
      next;
    }
    if (! $plobj) {
      mlog(0,"error loading plugin $pl: unable to create a new instance");
      next;
    }

    eval{@plconfig = $plobj->get_config()};
    if ($@) {
      mlog(0,"error loading plugin $pl (get_config) - error: $@");
      next;
    }
    if (! @plconfig) {
      mlog(0,"error reading plugin $pl configuration");
      next;
    }

    eval{$plinput = $plobj->get_input()};
    if ($@) {
      mlog(0,"error loading plugin $pl (get_input) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if (! $plinput && $plinput != 0) {
      mlog(0,"error reading plugin $pl INPUT");
      removePluginConfig($plobj);
      next;
    }

    eval{$ploutput = $plobj->get_output()};
    if ($@) {
      mlog(0,"error loading plugin $pl (get_output) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if (! $ploutput && $ploutput != 0) {
      mlog(0,"error reading plugin $pl OUTPUT");
      removePluginConfig($plobj);
      next;
    }

    eval{$version = $plobj->VERSION};
    if ($@) {
      mlog(0,"error loading plugin $pl (version) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if (! $version) {
      mlog(0,"error reading plugin $pl VERSION");
      removePluginConfig($plobj);
      next;
    }

    $tmp = "ASSP_Plugin_TEST";
    eval{$tmp = $plobj->process(0,\$tmp)};
    if ($@) {
      mlog(0,"error loading plugin $pl (process) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if ($tmp != 1) {
      mlog(0,"error plugin $pl process test returned $tmp - should be 1");
      removePluginConfig($plobj);
      next;
    }

    $tmp = "ASSP_Plugin_TEST";
    eval{$tmp = $plobj->tocheck()};
    if ($@) {
      mlog(0,"error loading plugin $pl (tocheck) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if ($tmp ne "ASSP_Plugin_TEST") {
      mlog(0,"error plugin $pl tocheck returned $tmp - should be ASSP_Plugin_TEST");
      removePluginConfig($plobj);
      next;
    }

    $tmp = '';
    eval{$tmp = $plobj->errstr()};
    if ($@) {
      mlog(0,"error loading plugin $pl (errstr) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if (! $tmp) {
      mlog(0,"error plugin $pl errstr returned undef");
      removePluginConfig($plobj);
      next;
    }

    $tmp = '';
    eval{$tmp = $plobj->result()};
    if ($@) {
      mlog(0,"error loading plugin $pl (result) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if ($tmp ne 'ASSP_Plugin_TEST') {
      mlog(0,"error plugin $pl result returned $tmp - should be ASSP_Plugin_TEST");
      removePluginConfig($plobj);
      next;
    }

    $tmp = '';
    eval{$tmp = $plobj->howToDo()};
    if ($@) {
      mlog(0,"error loading plugin $pl (howToDo) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if ($tmp != 9) {
      mlog(0,"error plugin $pl result returned $tmp - should be 9");
      removePluginConfig($plobj);
      next;
    }

    eval{$tmp = $plobj->close};
    if ($@) {
      mlog(0,"error loading plugin $pl (close) - error: $@");
      removePluginConfig($plobj);
      next;
    }
    if ($tmp != 1) {
      mlog(0,"error plugin $pl close returned undef - should be 1");
      removePluginConfig($plobj);
      next;
    }

    $Plugins{$pl} = &share({});
    $Plugins{$pl}->{version} = $version;
    $Plugins{$pl}->{input} = $plinput;
    $Plugins{$pl}->{output} = $ploutput;
    $runlvl0PL = 1 if ($plinput == 0);
    $runlvl1PL = 1 if ($plinput == 1);
    $runlvl2PL = 1 if ($plinput == 2);
    $plobj->close;
    mlog(0,"info: plugin $pl version $Plugins{$pl}->{version} loaded for runlevel ($plinput) - $runlevel[$plinput].");
  }
}
