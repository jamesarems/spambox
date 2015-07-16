#line 1 "sub main::callPlugin"
package main; sub callPlugin {
    my ($fh,$where,$mail) = @_;
    d('callPlugin');
    my $this = $Con{$fh};
    my $friend = $Con{$this->{friend}};
    my $plinput;
    my $ploutput;
    my %runpl = ();
    my $priority;
    my $enabled;
    my $plobj;
    my $result;
    my $resultstr;
    my $data;
    my $tocheck;
    my ($res,$reason,$reply);

    my @runlevel = ('\'SMTP-handshake\'','\'mail header\'','\'complete mail\'');
    if (! $$mail) {
      return 1,'','','' if ($where == 0 or $where == 1);  #there should be a value in $mail for runlevel 0/1
      $data = \$this->{header} if ($where == 1);
      $data = \$this->{header} if ($where == 2);
    } else {
      $data = $mail;
    }
    foreach my $pl (sort (keys %Plugins)) {
      next if ($where ne $Plugins{$pl}->{input});
      $enabled = "Do$pl";
      eval{${$enabled}=${$enabled}};
      if ($@) {
        mlog(0,"ERROR: $enabled - ConfigParm not found - the Plugin configuration is corrupt");
        next;
      }
      next if (! ${$enabled});       # Plugin is not enabled
      $priority = $pl."Priority";
      eval{$priority = ${$priority}};
      if ($@) {
        mlog(0,"ERROR: unable to set $pl runlevel priority - ConfigParm not found - the Plugin is corrupt");
        next;
      }
      while (exists $runpl{$priority}) {
        mlog(0,"WARNING: runlevel $runlevel[$where] - priority $priority is already occupied by plugin $runpl{$priority}");
        $priority++;
      }
      $runpl{$priority} = $pl;
    }
    foreach my $priority (sort(keys %runpl)) {
      &NewSMTPConCall();
      my $pl = $runpl{$priority};
      d("call Plugin $pl with priority: $priority in run level $runlevel[$where]");
      $plobj = $pl->new();
      if (! $plobj) {
        mlog(0,"ERROR: unable to call Plugin $pl (constructor)");
        next;
      }
      my $pltest1 = "Test$pl";
      $pltest = $$pltest1 ? $$pltest1 : $allTestMode;
      my $pldo1 = "Do$pl";
      $pldo = $$pldo1;
      my $plLogTo1 = $pl."LogTo";
      $plLogTo = $$plLogTo1;
      my $plVal1 = $pl."ValencePB";
      $plVal = defined ${$plVal1}[0] ? $plVal1 : $$plVal1;
      $result = $plobj->process(\$fh,$data);
      if (! $result){                   # Plugin call failed
        $resultstr = $plobj->errstr();
        $reason = $plobj->result() if (! $Plugins{$pl}->{output} && $plobj->result());
        $$data = $plobj->result() if ($Plugins{$pl}->{output} && $plobj->result());
        $plobj->close;
        if (($pldo == 3 || $pldo == 1) && ! $pltest) {
           pbAdd($fh,$this->{ip},$plVal,"$pl: $reason");
           delayWhiteExpire($fh);
           next if $pldo == 3 ;
        }
        return 0,$$data,$reason,$plLogTo,$resultstr,$pltest,$pl if (! $pltest);
      } else {                         # Plugin call ok
        $resultstr .= $pl."\001".$plobj->errstr()."\002";
        $tocheck = $plobj->tocheck();
        $$data = $plobj->result() if ($Plugins{$pl}->{output} && $plobj->result());
        $plobj->close;
        if ($tocheck && $where == 2){  # check the data we've got back from Plugin in runlvl 2
           ($res,$reason,$reply,$plLogTo) = &checkPluginData($fh,$tocheck,$where,$pldo,$pltest,$plLogTo,$pl);
           if (! $res) {    # the checks failed - return if PL is not in testmode
              return 0,$$data,$reason,$plLogTo,$reply,$pltest,$pl if (! $pltest);
           }
        }
      }
    }
    return 1,$$data,'',$plLogTo,$resultstr,'','all';
}
