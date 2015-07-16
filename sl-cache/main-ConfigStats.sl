#line 1 "sub main::ConfigStats"
package main; sub ConfigStats {
 my %tots = ();
 {
 lock(%Stats) if (is_shared(%Stats));
 if ($qs{ResetAllStats}) {
     if (&canUserDo($WebIP{$ActWebSess}->{user},'action','resetallstats')) {
         ResetAllStats();
     } else {
         return &webBlockText();
     }
 } elsif ($qs{ResetStats}) {
     if (&canUserDo($WebIP{$ActWebSess}->{user},'action','resetcurrentstats')) {
         ResetStats();
     } else {
         return &webBlockText();
     }
 }
 SaveStats();
 %tots=statsTotals();
 }
 delete $qs{ResetAllStats};
 delete $qs{ResetStats};
 my $upt=(time-$Stats{starttime})/(24*3600);
 my $upt2=(time-$AllStats{starttime})/(24*3600);
 my $resettime=localtime($AllStats{starttime});
 my $uptime=getTimeDiffAsString(time-$Stats{starttime},1);
 my $uptime2=getTimeDiffAsString(time-$AllStats{starttime});
 my $damptime=getTimeDiffAsString($Stats{damptime},1);
 my $damptime2=getTimeDiffAsString($AllStats{damptime});
 my $mpd=sprintf("%.1f",$upt==0 ? 0 : $tots{msgTotal}/$upt);
 my $mpd2=sprintf("%.1f",$upt2==0 ? 0 : $tots{msgTotal2}/$upt2);
 my $pct=sprintf("%.2f",$tots{msgTotal}-$Stats{locals}==0 ? 0 : 100*$tots{msgRejectedTotal}/($tots{msgTotal}-$Stats{locals}));
 my $pct2=sprintf("%.2f",$tots{msgTotal2}-$AllStats{locals}==0 ? 0 : 100*$tots{msgRejectedTotal2}/($tots{msgTotal2}-$AllStats{locals}));
 my $cpuAvg=sprintf("%.2f",(! $Stats{cpuTime} ? 0 : 100*$Stats{cpuBusyTime}/$Stats{cpuTime}));
 $cpuAvg = "99.00" if $cpuAvg > 99;
 my $cpuAvg2=sprintf("%.2f",(! $AllStats{cpuTime} ? 0 : 100*$AllStats{cpuBusyTime}/$AllStats{cpuTime}));
 $cpuAvg2 = "99.00" if $cpuAvg2 > 99;
#mlog(0,"info: cpuTime: $AllStats{cpuTime} - cpuBusyTime: $AllStats{cpuBusyTime}");

 my $wIdle = '<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\' bgcolor=lightyellow><tr><td>worker number</td><td>avg. CPU usage</td>';
 $wIdle .= '<td>used memory</td>' if $showMEM;
 $wIdle .= '</tr>';
 my $stime = time - $Stats{starttime};
 $stime ||= 1;
 for (0,1...$NumComWorkers,10000,10001) {
     my $offset = 0;
     my $wname = "Worker_$_";
     $wname = "Main_Thread" if $_ == 0;
     $offset = time - $WorkerLastAct{$_} if ($_ > 0 && $_ < 10000 && $ComWorker{$_}->{issleep});
     $wIdle .= '<tr><td>'.$wname.'</td><td>'.sprintf("%.2f \%",max((100*($stime - $offset - min(int($ThreadIdleTime{$_}+0.5),$stime))/$stime),0.1)).'</td>';
     $wIdle .= '<td>'.($CurrentMEM{$_} || 'n/a').'</td>' if $showMEM;
     $wIdle .= '</tr>';
 }
 $wIdle .= '</table>';

 my $currStat = &StatusASSP();
 $currStat = ($currStat =~ /not healthy/io)
   ? '<a href="./statusassp" target="blank" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>ASSP '.$version.$modversion.($codename?" ( code name $codename )":'').' is running not healthy! Click to show the current detail thread status.</td></tr></table>\', this, event, \'450px\', \'\'); return true;"><b><font color=\'red\'>&bull;</font></b></a>'
   : '<a href="./statusassp" target="blank" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>ASSP '.$version.$modversion.($codename?" ( code name $codename )":'').' is running healthy. Click to show the current detail thread status.</td></tr></table>\', this, event, \'450px\', \'\'); return true;"><font color=#66CC66>&bull;</font></a>';

 my $currAvgDamp = ($Stats{damping} && $DoDamping) ? sprintf("(%.2f%% avg of accepted connections)",($Stats{damping} / ($Stats{smtpConn} ? $Stats{smtpConn} : 1)) * 100) : '';
 my $allAvgDamp  = ($AllStats{smtpConn} && $DoDamping) ? sprintf("(%.2f%% avg of accepted connections)",($AllStats{damping} / ($AllStats{smtpConn} ? $AllStats{smtpConn} : 1)) * 100) : '';

 my $corrTotal  = "100";
 my $corrTotal2 = "100";
 $corrTotal  = sprintf("%.3f",(($tots{msgTotal} - ($Stats{rcptReportSpam} + $Stats{rcptReportHam})*3) / $tots{msgTotal}) * 100) if $tots{msgTotal};
 $corrTotal2 = sprintf("%.3f",(($tots{msgTotal2} - ($AllStats{rcptReportSpam} + $AllStats{rcptReportHam})*3) / $tots{msgTotal2}) * 100) if $tots{msgTotal2};

 my $LocalDNSStatus;
 
 if ($UseLocalDNS) {
     $LocalDNSStatus = "Local <a href=\"/#UseLocalDNS\">DNS Servers</a> in use";
 } else {
     $LocalDNSStatus = "Custom <a href=\"/#DNSServers\">DNS servers</a> in use";
 }

 my  ($modules,@dummy) = &StatsGetModules();

 my $reset = 'reset';
 my $restart = 'reset or restart';
 if (&canUserDo($WebIP{$ActWebSess}->{user},'action','resetallstats')) {
     $uptime2 = "<a href=\"javascript:void(0);\" title=\"click to reset all stats to zero\" onclick=\"if (confirm('reset all STATS ?')) {WaitDiv();window.location.href='/infostats?ResetAllStats=1';}\">$uptime2</a>";
     $reset = "<a href=\"javascript:void(0);\" title=\"click to reset all stats to zero\" onclick=\"if (confirm('reset all STATS ?')) {WaitDiv();window.location.href='/infostats?ResetAllStats=1';}\">reset</a>";
 }
 if (   &canUserDo($WebIP{$ActWebSess}->{user},'action','resetcurrentstats')
     or &canUserDo($WebIP{$ActWebSess}->{user},'action','resetallstats')) {
     $uptime = "<a href=\"javascript:void(0);\" title=\"click to reset all stats since last start to zero\" onclick=\"if (confirm('reset current STATS ?')) {WaitDiv();window.location.href='/infostats?ResetStats=1';}\">$uptime</a>";
     $restart = "<a href=\"javascript:void(0);\" title=\"click to reset all stats since last start to zero\" onclick=\"if (confirm('reset current STATS ?')) {WaitDiv();window.location.href='/infostats?ResetStats=1';}\">reset</a> or restart";
 }

my $ret = <<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<script type=\"text/javascript\">
<!--
  function toggleTbody(id) {
    if (document.getElementById) {
      var tbod = document.getElementById(id);
      if (tbod && typeof tbod.className == 'string') {
        if (tbod.className == 'off') {
          tbod.className = 'on';
        } else {
          tbod.className = 'off';
        }
      }
    }
    return false;
  }
//-->
</script>
   <div id="cfgdiv" class="content">
      <h2>
        $currStat ASSP Information and Statistics
      </h2><br />
      <table class="statBox">
        <thead>
          <tr>
            <td colspan="5" class="sectionHeader" onmousedown="toggleTbody('StatItem3')">
              General Runtime Information
            </td>
          </tr>
        </thead>
        <tbody id="StatItem3" class="on">
EOT

# General Runtime Information
$ret .= StatLine({'stat'=>'#uptime','text'=>'ASSP Proxy Uptime:','class'=>'statsOptionTitle'},
                 {'text'=>"$uptime",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$uptime2",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#msgTotal','text'=>'Messages Processed:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{msgTotal} ($mpd per day)",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{msgTotal2} ($mpd2 per day)",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#pctBlocked','text'=>'Non-Local Mail Blocked:','class'=>'statsOptionTitle'},
                 {'text'=>"$pct%",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$pct2%",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'(no)blocking correctness:<br />&nbsp;processed messages in relation to<br />&nbsp;reported spam + ham','class'=>'statsOptionTitle'},
                 {'text'=>"$corrTotal%",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$corrTotal2%",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#cpuAvg','text'=>'<a href="javascript:void(0);" onmouseover="showhint(\''.$wIdle.'\', this, event, \'300px\', \'1\');return false;">CPU Usage:</a>','class'=>'statsOptionTitle'},
                 {'text'=>"$cpuAvg% avg",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$cpuAvg2% avg",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'smtpMaxConcurrentSessions','text'=>'Concurrent SMTP Sessions:','class'=>'statsOptionTitle'},
                 {'text'=>"$smtpConcurrentSessions ($Stats{smtpMaxConcurrentSessions} max)",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpMaxConcurrentSessions} max",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'&nbsp;','class'=>'statsOptionValue','style'=>'background-color: #FFFFFF'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $restart at $starttime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $reset at $resettime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'})
;
$ret .= <<EOT;
        </tbody>
        <tbody>
          <tr>
            <td colspan="5" class="sectionHeader" onmousedown="toggleTbody('StatItem4')">
              Totaled Statistics
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem4" class="off">
EOT

# Totaled Statistics
$ret .= StatLine({'stat'=>'#smtpConnTotal','text'=>'SMTP Connections Received:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#smtpConnAcceptedTotal','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;SMTP Connections Accepted:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnAcceptedTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnAcceptedTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#smtpConnRejectedTotal','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;SMTP Connections Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnRejectedTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnRejectedTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptTotal','text'=>'Envelope Recipients Processed:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{rcptTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptAcceptedTotal','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Envelope Recipients Accepted:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptAcceptedTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{rcptAcceptedTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptRejectedTotal','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Envelope Recipients Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptRejectedTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{rcptRejectedTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#msgTotal','text'=>'Messages Processed:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{msgTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{msgTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#msgAcceptedTotal','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Messages Passed:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{msgAcceptedTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{msgAcceptedTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#msgRejectedTotal','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Messages Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{msgRejectedTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{msgRejectedTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#admConnTotal','text'=>'Admin Connections Received:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{admConnTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{admConnTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'admConn','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Admin Connections Accepted:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{admConn}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$AllStats{admConn}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'admConnDenied','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Admin Connections Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{admConnDenied}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$AllStats{admConnDenied}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'#statConnTotal','text'=>'Stat Connections Received:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{statConnTotal}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$tots{statConnTotal2}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'statConn','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Stat Connections Accepted:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{statConn}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$AllStats{statConn}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'statConnDenied','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Stat Connections Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{statConnDenied}",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$AllStats{statConnDenied}",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'&nbsp;','class'=>'statsOptionValue','style'=>'background-color: #FFFFFF'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $restart at $starttime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $reset at $resettime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'})
;
$ret .= <<EOT;
        </tbody>
        <tbody>
          <tr>
            <td colspan="5" class="sectionHeader" onmousedown="toggleTbody('StatItem5')">
              SMTP Connection Statistics
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem5" class="off">
EOT

#SMTP Connection Statistics
$ret .= StatLine({'stat'=>'smtpConn','text'=>'Accepted Logged SMTP Connections:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConn}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConn}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnSSL','text'=>'SSL-Port SMTP Connections:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnSSL}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnSSL}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnTLS','text'=>'STARTTLS SMTP Connections:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnTLS}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnTLS}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnNotLogged','text'=>'Not Logged SMTP Connections:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnNotLogged}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnNotLogged}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnLimit','text'=>'SMTP Connection Limits:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnLimit}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnLimit2}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnLimit','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Overall Limits:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnLimit}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnLimit}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnLimitIP','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;By IP Limits:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnLimitIP}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnLimitIP}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'delayConnection','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;By Delay on PB:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{delayConnection}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{delayConnection}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'AUTHErrors','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;By AUTH Errors Count:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{AUTHErrors}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{AUTHErrors}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnLimitFreq','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;By IP Frequency Limits:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnLimitFreq}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnLimitFreq}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnDomainIP','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;By Domain IP Limits:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnDomainIP}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnDomainIP}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpSameSubject','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;By Same Subjects Limits:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpSameSubject}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpSameSubject}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnIdleTimeout','text'=>'SMTP Connections Timeout:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnIdleTimeout}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnIdleTimeout2}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnSSLIdleTimeout','text'=>'SMTP SSL-Port-Connections Timeout:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnSSLIdleTimeout}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnSSLIdleTimeout2}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnTLSIdleTimeout','text'=>'SMTP STARTTLS-Connections Timeout:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{smtpConnTLSIdleTimeout}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$tots{smtpConnTLSIdleTimeout2}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'smtpConnDenied','text'=>'Denied SMTP Connections (enforced Extreme):','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{smtpConnDenied}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{smtpConnDenied}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'denyConnectionA','text'=>'Denied SMTP Connections (strict):','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{denyConnectionA}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{denyConnectionA}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'damping','text'=>'SMTP Connection damping:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{damping} $currAvgDamp",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{damping} $allAvgDamp",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'#damptime','text'=>'stolen time by damping:','class'=>'statsOptionTitle'},
                 {'text'=>"$damptime",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$damptime2",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'&nbsp;','class'=>'statsOptionValue','style'=>'background-color: #FFFFFF'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $restart at $starttime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $reset at $resettime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'})
;
$ret .= <<EOT;
        </tbody>
        <tbody>
          <tr>
            <td colspan="5" class="sectionHeader" onmousedown="toggleTbody('StatItem6')">
              Envelope Recipient Statistics
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem6" class="off">
EOT

# Envelope Recipient Statistics
$ret .= StatLine({'stat'=>'rcptAcceptedLocal','text'=>'Local Recipients Accepted:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptAcceptedLocal}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$tots{rcptAcceptedLocal2}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptValidated','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Validated Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptValidated}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptValidated}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptUnchecked','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Unchecked Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptUnchecked}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptUnchecked}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptSpamLover','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Spam-Lover Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptSpamLover}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptSpamLover}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptAcceptedRemote','text'=>'Remote Recipients Accepted:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptAcceptedRemote}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$tots{rcptAcceptedRemote2}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptWhitelisted','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Whitelisted Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptWhitelisted}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptWhitelisted}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptNotWhitelisted','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Not Whitelisted Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptNotWhitelisted}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptNotWhitelisted}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptUnprocessed','text'=>'Noprocessed Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptUnprocessed}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptUnprocessed}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptReport','text'=>'Email Reports:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptReport}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$tots{rcptReport2}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptReportSpam','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Spam Reports:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptReportSpam}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptReportSpam}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptReportHam','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Ham Reports:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptReportHam}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptReportHam}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptReportWhitelistAdd','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Whitelist Additions:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptReportWhitelistAdd}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptReportWhitelistAdd}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptReportWhitelistRemove','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Whitelist Deletions:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptReportWhitelistRemove}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptReportWhitelistRemove}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptReportRedlistAdd','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Redlist Additions:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptReportRedlistAdd}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptReportRedlistAdd}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'rcptReportRedlistRemove','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Redlist Deletions:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptReportRedlistRemove}",'class'=>'statsOptionValue positive','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptReportRedlistRemove}",'class'=>'statsOptionValue positive','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptRejectedLocal','text'=>'Local Recipients Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptRejectedLocal}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$tots{rcptRejectedLocal2}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptNonexistent','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Nonexistent Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptNonexistent}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptNonexistent}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptDelayed','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Delayed Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptDelayed}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptDelayed}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptDelayedLate','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Delayed (Late) Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptDelayedLate}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptDelayedLate}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptDelayedExpired','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Delayed (Expired) Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptDelayedExpired}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptDelayedExpired}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptEmbargoed','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Embargoed Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptEmbargoed}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptEmbargoed}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptSpamBucket','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Spam Bucketed Recipients:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptSpamBucket}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptSpamBucket}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'#rcptRejectedRemote','text'=>'Remote Recipients Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$tots{rcptRejectedRemote}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$tots{rcptRejectedRemote2}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'rcptRelayRejected','text'=>'&nbsp;&nbsp;&nbsp;&nbsp;Relay Attempts Rejected:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rcptRelayRejected}",'class'=>'statsOptionValue negative','colspan'=>'2'},
                 {'text'=>"$AllStats{rcptRelayRejected}",'class'=>'statsOptionValue negative','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'&nbsp;','class'=>'statsOptionValue','style'=>'background-color: #FFFFFF'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $restart at $starttime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $reset at $resettime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'})
;
$ret .= <<EOT;
        </tbody>
        <tbody>
          <tr>
            <td colspan="5" class="sectionHeader" onmousedown="toggleTbody('StatItem7')">
              Message Statistics
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem7" class="on">
EOT

my @msgStats = qw(
bhams whites locals noprocessing spamlover bspams blacklisted helolisted invalidHelo
forgedHelo mxaMissing ptrMissing ptrInvalid spambucket penaltytrap viri viridetected
bombBlack bombs bombSender pbdenied pbextreme denyConnection sbblocked msgscoring
senderInvalidLocals internaladdresses scripts spffails rblfails uriblfails msgMaxVRFYErrors
msgBackscatterErrors msgMSGIDtrErrors batvErrors msgMaxErrors msgDelayed msgNoRcpt
msgNoSRSBounce dkimpre dkim localFrequency preHeader msgverify crashAnalyze Razor DCC
);
my %st;
map {$st{$_} = $Stats{$_};} @msgStats;
my ($smin,$smax) = minmax(\%st);
%st =();
map {$st{$_} = $AllStats{$_};} @msgStats;
my ($amin,$amax) = minmax(\%st);
%st = ();
@msgStats = ();
# Message Statistics
$ret .= StatLine({'stat'=>'bhams','text'=>'Message OK:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{bhams}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{bhams}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'whites','text'=>'Whitelisted:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{whites}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{whites}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'locals','text'=>'Local:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{locals}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{locals}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'noprocessing','text'=>'Noprocessing:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{noprocessing}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{noprocessing}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'spamlover','text'=>'Spamlover Spams Passed:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{spamlover}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{spamlover}",'class'=>'statsOptionValue positive','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'bspams','text'=>'Bayesian/HMM Spams:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{bspams}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{bspams}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'blacklisted','text'=>'Domains Blacklisted:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{blacklisted}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{blacklisted}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'helolisted','text'=>'HELO Blacklisted:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{helolisted}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{helolisted}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'invalidHelo','text'=>'HELO Invalid:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{invalidHelo}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{invalidHelo}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'forgedHelo','text'=>'HELO Forged:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{forgedHelo}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{forgedHelo}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'mxaMissing','text'=>'Missing MX and A Record:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{mxaMissing}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{mxaMissing}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'ptrMissing','text'=>'Missing PTR Record:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{ptrMissing}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{ptrMissing}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'ptrInvalid','text'=>'Invalid PTR Record:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{ptrInvalid}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{ptrInvalid}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'spambucket','text'=>'Spam Collected Messages:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{spambucket}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{spambucket}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'penaltytrap','text'=>'Penalty Trap Messages:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{penaltytrap}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{penaltytrap}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'viri','text'=>'Bad Attachments:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{viri}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{viri}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'viridetected','text'=>'Viruses Detected:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{viridetected}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{viridetected}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'bombBlack','text'=>'Black Regex:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{bombBlack}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{bombBlack}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'bombs','text'=>'Bomb Regex:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{bombs}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{bombs}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'bombSender','text'=>'Bomb - Sender/Header Regex:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{bombSender}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{bombSender}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'pbdenied','text'=>'Penalty Box:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{pbdenied}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{pbdenied}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'pbextreme','text'=>'PenaltyBox Extreme:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{pbextreme}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{pbextreme}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'denyConnection','text'=>'Deny Connection:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{denyConnection}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{denyConnection}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'sbblocked','text'=>'CountryCode blocked:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{sbblocked}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{sbblocked}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgscoring','text'=>'Message Scoring:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgscoring}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgscoring}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'senderInvalidLocals','text'=>'Invalid Sender:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{senderInvalidLocals}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{senderInvalidLocals}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'internaladdresses','text'=>'Invalid Internal Mail:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{internaladdresses}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{internaladdresses}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'scripts','text'=>'Scripts:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{scripts}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{scripts}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'spffails','text'=>'SPF Failures:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{spffails}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{spffails}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'rblfails','text'=>'RBL Failures:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{rblfails}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{rblfails}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'uriblfails','text'=>'URIBL Failures:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{uriblfails}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{uriblfails}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgMaxVRFYErrors','text'=>'Max VRFY Errors:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgMaxVRFYErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgMaxVRFYErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgBackscatterErrors','text'=>'BackScatter Errors:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgBackscatterErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgBackscatterErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgMSGIDtrErrors','text'=>'MSGID signing Errors:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgMSGIDtrErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgMSGIDtrErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'batvErrors','text'=>'BATV Errors:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{batvErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{batvErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgMaxErrors','text'=>'Max Errors Exceeded:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgMaxErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgMaxErrors}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgDelayed','text'=>'Delayed/Greylisted:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgDelayed}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgDelayed}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgNoRcpt','text'=>'Empty Recipient:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgNoRcpt}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgNoRcpt}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgNoSRSBounce','text'=>'Unsigned SRS Bounces:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgNoSRSBounce}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgNoSRSBounce}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'dkimpre','text'=>'DKIM pre Check:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{dkimpre}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{dkimpre}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'dkim','text'=>'DKIM Signature:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{dkim}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{dkim}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'localFrequency','text'=>'local frequency:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{localFrequency}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{localFrequency}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'preHeader','text'=>'early (pre)Header:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{preHeader}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{preHeader}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'msgverify','text'=>'uuencoded and Header error:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{msgverify}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{msgverify}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'crashAnalyze','text'=>'Crash Analyzer:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{crashAnalyze}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{crashAnalyze}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'Razor','text'=>'ASSP_Razor Plugin:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{Razor}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{Razor}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'DCC','text'=>'ASSP_DCC Plugin:','class'=>'statsOptionTitle'},
                 {'text'=>"$Stats{DCC}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$smin,'max'=>$smax},
                 {'text'=>"$AllStats{DCC}",'class'=>'statsOptionValue negative','colspan'=>'2','min'=>$amin,'max'=>$amax})

      . StatLine({'stat'=>'','text'=>'&nbsp;','class'=>'statsOptionValue','style'=>'background-color: #FFFFFF'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $restart at $starttime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $reset at $resettime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'})
;
$ret .= <<EOT;
        </tbody>
        <tbody>
          <tr>
            <td class="sectionHeader" onmousedown="toggleTbody('StatItem8')" colspan="5">
              Message Scoring Statistics
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem8" class="off">
EOT

my %tmpStats = %ScoreStats;
($smin,$smax) = minmax(\%ScoreStats);
($amin,$amax) = minmax(\%AllScoreStats);
for (sort {lc($main::a) cmp lc($main::b)} qw(
 ASSP_AFC ASSP_DCC ASSP_OCR ASSP_Razor AUTHErrors Backscatter-failed BadAttachment BadHistory BATV-check-failed Bayesian Bayesian-HAM
 BlacklistedDomain BlacklistedHelo BlackOrg BlockedCountry BombBlack BombCharSets BombData BombHeaderRe bombRe BombScript
 BombSenderHelo BombSenderIP BombSenderMailFrom BombSubjectRe bombSuspiciousRe CountryCode DKIMfailed DKIMpass DMARC-failed DNSBLfailed
 DNSBLneutral EarlyTalker ExtremeHistory ForgedHELO From-missing griplist HMM HMM-HAM HomeCountry internaladdress InvalidAddress
 InvalidHELO InvalidLocalSender InWhiteBox IPfrequency IPinHELO IPinHELOmismatch KnownGoodHelo LimitingIP LimitingIPDomain LimitingSameSubject
 MaxDuplicateRcpt MaxErrors MessageOK MissingMX MissingMXA Msg-IDinvalid Msg-IDmissing Msg-IDnotvalid Msg-IDsuspicious
 MSGID-signature-failed NeedRecipient NoCountryNoOrg NoSpoofing penaltytrap PTRinvalid PTRmissing RelayAttempt SIZE
 SpamCollectAddress SPFerror SPFfail SPFfail-strict SPFneutral SPFneutral-strict SPFnone SPFnone-strict SPFpass
 SPFsoftfail SPFsoftfail-strict SRS_Not_Signed SSL-TLS-connection-OK SuspiciousVirus-ClamAV
 SuspiciousVirus-FileScan TimeOut URIBLfailed URIBLneutral ValidHELO virus-ClamAV virus-FileScan WhiteSenderBase)
 )
{

    $ret .= StatLine({'stat'=>";$_",'text'=>"$_:",'class'=>'statsOptionTitle'},
                     {'text'=>"$ScoreStats{$_}",'class'=>'statsOptionValue','colspan'=>'2','style'=>'color: blue','min'=>$smin,'max'=>$smax},
                     {'text'=>"$AllScoreStats{$_}",'class'=>'statsOptionValue','colspan'=>'2','style'=>'color: blue','min'=>$amin,'max'=>$amax});
    delete $tmpStats{$_};
}
foreach (sort keys %tmpStats) {
    mlog(0,"error: unknown/unregistered ScoreStats name '$_' - this has been corrected!");
    delete $ScoreStats{$_};
    delete $AllScoreStats{$_};
    delete $OldScoreStats{$_};
}
$ret .= StatLine({'stat'=>'','text'=>'&nbsp;','class'=>'statsOptionValue','style'=>'background-color: #FFFFFF'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $restart at $starttime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'},
                 {'text'=>"<font size=\"1\" color=\"#C0C0C0\"><em>since $reset at $resettime</em></font>",'class'=>'statsOptionValue','style'=>'background-color: #FFFFFF','colspan'=>'2'})
;
$ret .= <<EOT;
        </tbody>
EOT

# Server Information

$ret .= <<EOT;
        <tbody>
          <tr>
            <td class="sectionHeader" onmousedown="toggleTbody('StatItem0')" colspan="5">
              Server Information
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem0" class="off">
EOT

my $dns_avg = sprintf("%.3f",($DNSsumQueryTime/($DNSQueryCount || 1)));
my $dns_max = sprintf("%.3f",$DNSmaxQueryTime);
my $dns_min = sprintf("%.3f",$DNSminQueryTime);

$ret .= StatLine({'stat'=>'','text'=>'Server Name:','class'=>'statsOptionTitle'},
                 {'text'=>"$localhostname",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'ASSP host UUID:','class'=>'statsOptionTitle'},
                 {'text'=>"$UUID",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'Server OS:','class'=>'statsOptionTitle'},
                 {'text'=>"$^O",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'Server IP:','class'=>'statsOptionTitle'},
                 {'text'=>"$localhostip",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'DNS Servers:','class'=>'statsOptionTitle'},
                 {'text'=>"@nameservers",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"$LocalDNSStatus",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'DNS Servers query time:','class'=>'statsOptionTitle'},
                 {'text'=>"min: $dns_min , avg: $dns_avg , max: $dns_max",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'Perl Version:','class'=>'statsOptionTitle'},
                 {'text'=>"$]",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"<a href=\"http://www.perl.org/get.html\" rel=\"external\" target=\"_blank\">Perl.org</a>",'class'=>'statsOptionValueC','colspan'=>'2'})
;
my ($totalmem,$freemem,$totalswap,$freeswap);
if ($CanUseSysMemInfo) {
   $totalmem = eval{int(Sys::MemInfo::totalmem() / 1048576);};
   $freemem = eval{int(Sys::MemInfo::freemem() / 1048576);};
   $totalswap = eval{int(Sys::MemInfo::totalswap() / 1048576);};
   $freeswap = eval{int(Sys::MemInfo::freeswap() / 1048576);};
}
if ($totalmem) {
$ret .= StatLine({'stat'=>'','text'=>'physical-memory:','class'=>'statsOptionTitle'},
                 {'text'=>"$totalmem MB",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'free physical-memory:','class'=>'statsOptionTitle'},
                 {'text'=>"$freemem MB",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'total virtual-memory:','class'=>'statsOptionTitle'},
                 {'text'=>"$totalswap MB",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'free virtual-memory:','class'=>'statsOptionTitle'},
                 {'text'=>"$freeswap MB",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})
;
}

if (my $memusage = int(&memoryUsage() / 1048576)) {
my $minmem = int($minMemUsage / 1048576);
my $maxmem = int($maxMemUsage / 1048576);
$ret .= StatLine({'stat'=>'','text'=>'assp-process-memory:','class'=>'statsOptionTitle'},
                 {'text'=>"current: $memusage MB",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"min: $minmem MB</td><td>max: $maxmem MB",'class'=>'statsOptionValue'})
}

if ($CanUseSysCpuAffinity) {
$ret .= StatLine({'stat'=>'','text'=>'Number of CPU\'s:','class'=>'statsOptionTitle'},
                 {'text'=>"$numcpus",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})

      . StatLine({'stat'=>'','text'=>'Cpu Affinity:','class'=>'statsOptionTitle'},
                 {'text'=>"@currentCpuAffinity",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'})
;
}

$ret .= StatLine({'stat'=>'','text'=>'Spamdb version:','class'=>'statsOptionTitle'},
                 {'text'=>"used:</td><td>$currentDBVersion{Spamdb}",'class'=>'statsOptionValue'},
                 {'text'=>"required:</td><td>$requiredDBVersion{Spamdb}",'class'=>'statsOptionValue'});

$ret .= StatLine({'stat'=>'','text'=>'HMMdb version:','class'=>'statsOptionTitle'},
                 {'text'=>"used:</td><td>$currentDBVersion{HMMdb}",'class'=>'statsOptionValue'},
                 {'text'=>"required:</td><td>$requiredDBVersion{HMMdb}",'class'=>'statsOptionValue'});

my $currentCL = (-e "$base/docs/changelog.txt") ? "docs/changelog.txt" : '';
my $currentCLtext = $currentCL ? '<a href="javascript:void(0);" onclick="javascript:popFileEditor(\'docs/changelog.txt\',8);">show current local change log</a>' : '&nbsp;';
$ret .= <<EOT;
          <tr>
            <td class="statsOptionTitle">
              ASSP Version:
            </td>
            <td class="statsOptionValue" colspan="2">
              <table>
               <tr>
                <td rowspan="2">
                 $version$modversion
                </td>
                <td class="statsOptionValueC">
                 $currentCLtext
                </td>
               </tr>
               <tr>
                <td class="statsOptionValueC">
                 <a href="$ChangeLogURL" rel="external" target="_blank">show last available change log</a>
                </td>
               </tr>
              </table>
            </td>
            <td class="statsOptionValueC">
              <a href="http://sourceforge.net/project/showfiles.php?group_id=69172" rel="external" target="_blank">release</a>
            </td>
            <td class="statsOptionValueC">
              <a href="http://assp.cvs.sourceforge.net/viewvc/assp/assp2/" rel="external" target="_blank">beta</a>
            </td>
          </tr>
          <tr>
            <td class="statsOptionValue" style="background-color: #FFFFFF">
              &nbsp;
            </td>
            <td class="statsOptionValue" style="background-color: #FFFFFF" colspan="2">
              &nbsp;
            </td>
            <td class="statsOptionValueC" style="background-color: #FFFFFF" colspan="2">
              <font size="1" color="#C0C0C0"><em>downloads</em></font>
            </td>
          </tr>
        </tbody>
EOT

# license information
if (my $l = eval{$L->($T[0])}) {
$ret .= <<EOT;
        <tbody>
          <tr>
            <td class="sectionHeader" onmousedown="toggleTbody('StatItem9')" colspan="5">
              License Information
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem9" class="off">
EOT

$ret .= StatLine({'stat'=>'','text'=>'ASSP License Identifier (UUID) :','class'=>'statsOptionTitle'},
                 {'text'=>"$UUID",'class'=>'statsOptionValue','colspan'=>'2'},
                 {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'});
my @lic;
my @val;
map { $lic[int($_)] = {} } keys(%{$reglic});
map { $lic[int($_)] = $l->{license}->{"$_"} } keys(%{$l->{license}});

if ($#T >= 1 ) {
    for (1...$#T) {
        next unless $T[$_];
        my $l;
        next unless ($l = eval{$L->($T[$_])});
        map { $lic[int($_)] = $l->{license}->{"$_"} } keys(%{$l->{license}});
        map { $val[int($_)] = $l->{validate}->{"$_"} } keys(%{$l->{validate}});
    }
}
for my $m (0...$#lic) {
    next unless $lic[$m];
    my $error;
    my $class = 'statsOptionValue positive';
    my $text = 'valid license';
    if (! keys(%{$lic[$m]})) {
        $class = 'statsOptionValue negative';
        $text = "no valid license";
        $error = 1;
    }
    if (! $error && defined $val[$m] && ! eval{$val[$m]->($lic[$m],$UUID)}) {
        $class = 'statsOptionValue negative';
        $text = $@ ? "license validation error - call the vendor" : 'foreign license or license violation';
        $error = 1;
    }
    $ret .= StatLine({'stat'=>'','text'=>"&nbsp;",'class'=>'statsOptionTitle'},
                     {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'},
                     {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'});
    $ret .= StatLine({'stat'=>'','text'=>$licmap->{sprintf("%02d",$m)}.' :','class'=>'statsOptionTitle'},
                     {'text'=>$text,'class'=>$class,'colspan'=>'2'},
                     {'text'=>"&nbsp;",'class'=>'statsOptionValue','colspan'=>'2'});
    foreach my $s (sort keys(%{$lic[$m]})) {
        next if $error && int($s) > 6;
        my $text = $lic[$m]->{$s};
        my $class = 'statsOptionValue';
        if (int($s) == 8) {
             if ($text >= 9999999999) {
                 $class = 'statsOptionValue positive';
                 $text = 'no expiration';
             } elsif ($text < time) {
                 $class = 'statsOptionValue negative';
                 $text = timestring($text).' (expired)';
             } else {
                 $class = 'statsOptionValue positive';
                 $text = timestring($text);
             }
        }
        $text =~ s/((?:(?:ht|f)tps?|file):\/\/[\w.\/\_\-\?\=\&\%\;]+)/'<a href="'.$1.'" target="_blank">'.$1.'<\/a>'/geoi;
        $ret .= StatLine({'stat'=>'','text'=>"&nbsp;",'class'=>'statsOptionTitle'},
                         {'text'=>$licmap->{$s}.':','class'=>'statsOptionValue','colspan'=>'2'},
                         {'text'=>$text,'class'=>$class,'colspan'=>'2'});
    }
}

$ret .= <<EOT;
        </tbody>
EOT
}

# module information

$ret .= <<EOT;
        <tbody>
          <tr>
            <td class="sectionHeader" onmousedown="toggleTbody('StatItem2')" colspan="5">
              Perl Modules
            </td>
          </tr>
        </tbody>
        <tbody id="StatItem2" class="off">
EOT

$ret .= $modules;
$ret .= <<EOT;
          <tr>
            <td class="statsOptionValue" style="background-color: #FFFFFF">
              &nbsp;
            </td>
            <td class="statsOptionValue" style="background-color: #FFFFFF" colspan="2">
              &nbsp;
            </td>
            <td class="statsOptionValueC" style="background-color: #FFFFFF" colspan="2">
              <font size="1" color="#C0C0C0"><em>downloads</em></font>
            </td>
          </tr>
        </tbody>
      </table><br />
      $kudos<br />
    </div>
    $footers
<form name="ASSPconfig" id="ASSPconfig" action="" method="post">
  <input name="theButtonLogout" type="hidden" value="" />
</form>
</body></html>
EOT
$ret;
}
