#line 1 "sub main::ShutdownList"
package main; sub ShutdownList {
    my $action = $qs{action};
    my $forceRefresh = $qs{forceRefresh};
    my $nocache = $qs{nocache};
    my $showcolor = $qs{showcolor} ? 1 : 0;
    my $showreports = $qs{showreports} ? 1 : 0;
    my ($refreshtime) = $qs{refreshtime} =~ /^(\d+)$/o;
    $refreshtime ||= 2;
    my ( $s1, $s2, $editButtons, $query, $refresh );
    my %conperwo = ();
    my $rowclass;
    my $shutdownDelay = 2;
    my $SMTPSessionCount;
    $lastThreadsDoStatus = time;
    mlog(0,"info: Threads collecting status information") if(! $ThreadsDoStatus && $MaintenanceLog);
    if (! $ThreadsDoStatus) {
       $MailCountTmp = 0;
       $MailTimeTmp = 0;
       $MailProcTimeTmp = 0;
    }
    $ThreadsDoStatus = 1;
    my $duration = $MailCount ? $MailTime / $MailCount : 0;
    $duration = sprintf("%.2f",$duration);
    my $proctime = $MailCount ? $MailProcTime / $MailCount : 0;
    $proctime = sprintf("%.2f",$proctime);
    my $durationTmp = $MailCountTmp ? $MailTimeTmp / $MailCountTmp : 0;
    $durationTmp = sprintf("%.2f",$durationTmp);
    my $proctimeTmp = $MailCountTmp ? $MailProcTimeTmp / $MailCountTmp : 0;
    $proctimeTmp = sprintf("%.2f",$proctimeTmp);
    my $TransferTimeTmp = $TransferCount ? sprintf("%.3f",$TransferTime / $TransferCount) : 0;
    my $TransferNoInterrupt = $TransferCount-$TransferInterrupt;
    my $TransferNoInterruptTimeTmp = $TransferNoInterrupt ? sprintf("%.3f",$TransferNoInterruptTime /$TransferNoInterrupt) : 0;
    my $TransferInterruptTimeTmp = $TransferInterrupt ? sprintf("%.3f",$TransferInterruptTime /$TransferInterrupt) : 0;
    my $d_bw = $TransferInterrupt ? sprintf("%.3f",$i_bw_time /$TransferInterrupt) : 0;
    my $d_tw = $TransferInterrupt ? sprintf("%.3f",$i_tw_time /$TransferInterrupt) : 0;
    my $RecomWorkers = &calcWorkers();
    my $totalmem = "n/a";
    my $freemem = "n/a";
    my $totalswap = "n/a";
    my $freeswap = "n/a";
    if ($CanUseSysMemInfo) {
       $totalmem = eval{int(Sys::MemInfo::totalmem() / 1048576);};
       $freemem = eval{int(Sys::MemInfo::freemem() / 1048576);};
       $totalswap = eval{int(Sys::MemInfo::totalswap() / 1048576);};
       $freeswap = eval{int(Sys::MemInfo::freeswap() / 1048576);};
    }
    $query  = '?nocache='.time;
    $query .= '&forceRefresh=1' if $forceRefresh;
    my $focusJS = '
<script type="text/javascript">
 var refreshtime = '.$refreshtime.';
//noprint
 Timer=setTimeout("newTimer();", 1000 * refreshtime);
//endnoprint
 ';
 $focusJS .= $forceRefresh ? '
 var Run = 1;
 function tStop () {
    Run = 1;
 }
 '
 :
 '
 var Run = 1;
 function tStop () {
    Run = 0;
    Timer=setTimeout("noop();", 1000 * refreshtime);
 }
 ';
 
 $focusJS .= '
 function noop () {}
 var Run2 = 1;
 var linkBG;
 var showcolor = '.$showcolor.';
 var showreports = '.$showreports.';
//noprint
 setcolorbutton();
 setreportsbutton();
 function startstop() {
     Run2 = (Run2 == 1) ? 0 : 1;
     document.getElementById(\'stasto\').value = (Run2 == 1) ? "Stop" : "Start";
 }
 function tStart () {
    Run = 1;
 }
 function newTimer() {
   if (Run == 1 && Run2 == 1) {window.location.reload();}
   Timer=setTimeout("newTimer();", 1000 * refreshtime);
 }
//endnoprint

function popAddressAction(address)
{
  var height = 500 ;
  var link = address ? \'?address=\'+address : \'\';
  newwindow=window.open(
    \'addraction\'+link,
    \'AddressAction\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function popIPAction(ip)
{
  var height = 500 ;
  var link = ip ? \'?ip=\'+ip : \'\';
  newwindow=window.open(
    \'ipaction\'+link,
    \'IPAction\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

//noprint
function switchcolor () {
    showcolor = (showcolor == 1) ? 0 : 1;
    setcolorbutton();
    setcolor();
}
function setcolor () {
    if (showcolor == 1) {
        window.location.href=\'./shutdown_list?nocache='.$nocache.'&forceRefresh='.$forceRefresh.'&showreports='.$showreports.'&showcolor=1&refreshtime=\'+refreshtime;
    } else {
        window.location.href=\'./shutdown_list?nocache='.$nocache.'&forceRefresh='.$forceRefresh.'&showreports='.$showreports.'&showcolor=0&refreshtime=\'+refreshtime;
    }
}
function setcolorbutton () {
    if (showcolor == 1) {
        document.getElementById(\'colorbutton\').value = "color-off";
    } else {
        document.getElementById(\'colorbutton\').value = "color-on";
    }
}

function switchreports () {
    showreports = (showreports == 1) ? 0 : 1;
    setreportsbutton();
    setreports();
}
function setreports () {
    if (showreports == 1) {
        window.location.href=\'./shutdown_list?nocache='.$nocache.'&forceRefresh='.$forceRefresh.'&showcolor='.$showcolor.'&showreports=1&refreshtime=\'+refreshtime;
    } else {
        window.location.href=\'./shutdown_list?nocache='.$nocache.'&forceRefresh='.$forceRefresh.'&showcolor='.$showcolor.'&showreports=0&refreshtime=\'+refreshtime;
    }
}
function setreportsbutton () {
    if (showreports == 1) {
        document.getElementById(\'reportsbutton\').value = "reports-off";
    } else {
        document.getElementById(\'reportsbutton\').value = "reports-on";
    }
}

function switchtime () {
    refreshtime = document.getElementById(\'refreshtime\').value;
    window.location.href=\'./shutdown_list?nocache='.$nocache.'&forceRefresh='.$forceRefresh.'&showcolor='.$showcolor.'&showreports='.$showreports.'&refreshtime=\'+refreshtime;
}
//endnoprint

function processPrint(){
    if (document.getElementById != null){
        var html = \'<HTML>\n<HEAD>\n\';
        if (document.getElementsByTagName != null){
            var headTags = document.getElementsByTagName("head");
            if (headTags.length > 0) html += headTags[0].innerHTML;
        }
        html = html.replace(/noprint(?:.|\n)+?endnoprint/g, \'\');
        html += \'\n</HE\' + \'AD>\n<BODY>\n\';
        html += \'<img src="get?file=images/logo.gif" />&nbsp;&nbsp;&nbsp;<b>SPAMBOX version '.$version.$modversion.'</b><br /><hr /><br />\';

        var printReadyElemCfg  = document.getElementById("cfgdiv");

        if (printReadyElemCfg  != null)  html += printReadyElemCfg.innerHTML;
        html = html.replace(/<input.+?>/g, \'\');
        html += \'\n<script type="text/javascript">\n window.print();\n<\/script>\n\';
        html += \'\n</BO\' + \'DY>\n</HT\' + \'ML>\';
        var printWin = window.open("","processPrint");
        printWin.document.open();
        printWin.document.write(html);
        printWin.document.close();

    } else alert("Browser not supported.");
}
</script>
';
        $refresh = 1;
        $s1 = '<div class="contentFoot" style="margin:0; text-align:left;">';
        $s1 .= '<style type="text/css">
                   th {text-align: right;}
                </style>';
        $s1 .= '<table CELLSPACING=0 CELLPADDING=4 WIDTH="98%" style="margin:0; text-align:left;"><tr>';
        $SMTPSessionCount = scalar(keys %ConFno);
        my $memusage = int(&memoryUsage() / 1048576);
        threads->yield;
        $s1 .= '<th>SMTP sessions' . " in threads:</th><td>$SMTPSessionCount</td><th>global:</th><td>$smtpConcurrentSessions</td><th>total:</th><td>$SMTPSessionIP{Total}</td></tr>";
        $s1 .= '</table></div>' unless $ShowPerformanceData;
        $s1 .= '<tr><th>processed emails:</th><td>'.$MailCount.'/'.$MailCountTmp.'</td><th>average duration:</th><td>'.$duration.'/'.$durationTmp.'</td><th>average real processing time:</th><td>'.$proctime.'/'.$proctimeTmp.'</td></tr>'
          . '<tr><th>Connection Transfer count/time:</th><td>' . "$TransferCount/$TransferTimeTmp" . '</td><th>without interrupt:</th><td>' . "$TransferNoInterrupt/$TransferNoInterruptTimeTmp" . '</td><th>with interrupt:</th><td>' . "$TransferInterrupt/$TransferInterruptTimeTmp" . "</td><th>interrupt select time:</th><td>$d_bw</td>" . "<th>interrupt wait time:</th><td>$d_tw</td>"
          . '</tr><tr>'
          . "<th>running Workers:</th><td>$NumComWorkers</td><th>recommended Workers:</th><td>$RecomWorkers</td>"
          . ($memusage ? "<th>total process-memory:</th><td>$memusage MB</td>" : '')
          . '</tr><tr>'
          . "<th>total physical-memory:</th><td>$totalmem MB</td><th>free physical-memory:</th><td>$freemem MB</td><th>total virtual-memory:</th><td>$totalswap MB</td><th>free virtual-memory:</th><td>$freeswap MB</td>"
          . ($CanUseSysCpuAffinity?"<th>CPU Affinity:</th><td>@currentCpuAffinity (from total $numcpus CPU's)</td>":'')
          . "</tr></table></div>\n"
              if $ShowPerformanceData;

        $s2 =
            "<tr><td class=\"conTabletitle\"># TLS</td><td class=\"conTabletitle\">WKR(Con)</td><td class=\"conTabletitle\">Remote IP</td><td class=\"conTabletitle\">HELO</td><td class=\"conTabletitle\">From</td><td class=\"conTabletitle\">Rcpt</td><td class=\"conTabletitle\">CMD</td><td class=\"conTabletitle\">RP/RY/NP/WL</td><td class=\"conTabletitle\">SPAM/score</td><td class=\"conTabletitle\">Bytes</td><td class=\"conTabletitle\">Duration</td><td class=\"conTabletitle\">Idle/Damping</td></tr>";

	    my $tmpTimeNow = time;
        my %tConFno = ();
        threads->yield();
        %tConFno = %ConFno;
        threads->yield();
        my @tmpConKeys = keys(%tConFno);
        my @tmpConSortedKeys =
          sort { $tConFno{$main::a}->{isreport}  cmp $tConFno{$main::b}->{isreport} or   # reports last
                 $tConFno{$main::a}->{timelast}  <=> $tConFno{$main::b}->{timelast} or   # last action
                 $tConFno{$main::a}->{timestart} <=> $tConFno{$main::b}->{timestart}     # start time
               } @tmpConKeys;
        my $tmpCount = 0;
        foreach my $key (@tmpConSortedKeys) {
                next unless ($tConFno{$key}->{worker});
                next if (! $showreports && $tConFno{$key}->{isreport});
                $conperwo{$tConFno{$key}->{worker}}++;
            	$tmpCount++;
                $tConFno{$key}->{messagescore} ||= 0;
                $tConFno{$key}->{spamfound} ||= $tConFno{$key}->{lastcmd} =~ /error/io;
                my $tmpDuration = $tmpTimeNow - $tConFno{$key}->{timestart};
                my $tmpInactive = $tmpTimeNow - $tConFno{$key}->{timelast};
                my $relay = $tConFno{$key}->{relayok} ? 'OUT' : 'IN';
                $relay .= '/NP' if $tConFno{$key}->{noprocessing};
                $relay .= '/WL' if $tConFno{$key}->{whitelisted};
                $relay = $tConFno{$key}->{isreport} if $tConFno{$key}->{isreport};
                my $damping = $tConFno{$key}->{damping} ? '&nbsp;/&nbsp;D&nbsp;' : '';
                if ($damping && $DoDamping) {
                    my $dampOffset = 0;
#                    $dampOffset = $DoDamping * 10 if ! $tConFno{$key}->{messagescore} && &pbBlackFind($tConFno{$key}->{ip});
                    my $damptime = int(($tConFno{$key}->{messagescore} + $dampOffset) / $DoDamping) - $tmpInactive;
                    $damptime = $damptime > 0 ? $damptime > $maxDampingTime ? $maxDampingTime - $tmpInactive: $damptime : 0;
                    $damptime = 2 if ($damptime > 2 && lc $tConFno{$key}->{lastcmd} eq 'data' && ! $tConFno{$key}->{headerpassed});
                    $damping .= $damptime;
                }
                my $bgcolor;
                if ($showcolor) {
                    $bgcolor = ' style="background-color:#7CFC7F;"' if $tConFno{$key}->{whitelisted};
                    $bgcolor = ' style="background-color:#7CFC00;"' if $tConFno{$key}->{noprocessing};
                    $bgcolor = ' style="background-color:#7CFCFF;"' if $tConFno{$key}->{relayok} || $tConFno{$key}->{isreport};
                    my $cc = 255;
                    $cc -= int($tConFno{$key}->{messagescore} * 127 / $PenaltyMessageLimit) if $PenaltyMessageLimit;
                    $cc = 63 if $PenaltyMessageLow && $tConFno{$key}->{messagescore} >= $PenaltyMessageLow;
                    $cc = 0 if $cc < 0 or ($PenaltyMessageLimit && $tConFno{$key}->{messagescore} >= $PenaltyMessageLimit);
                    $cc = sprintf("%02X",$cc);
                    $bgcolor = ' style="background-color:#FF'.$cc.'00;"' if $tConFno{$key}->{messagescore} > 0;
                    $bgcolor = ' style="background-color:#FF0000;"' if $tConFno{$key}->{spamfound};
                }
                if ($tmpCount%2==1) {
        			$rowclass = "\n<tr$bgcolor>";
        		} else {
        			$rowclass = "\n<tr class=\"even\"$bgcolor>";
        		}
                $s2 .= $rowclass
                  . "<td $bgcolor><b>"
                  . ( $tmpCount ) . ' ' .$tConFno{$key}->{ssl}.$tConFno{$key}->{friendssl}
                  . "</b></td><td $bgcolor>"
                  . $tConFno{$key}->{worker}.'('.$conperwo{$tConFno{$key}->{worker}}.')'
                  . "</td><td $bgcolor>" .

                  (
                  (! ($tConFno{$key}->{relayok} || $tConFno{$key}->{isreport}) && &canUserDo($WebIP{$ActWebSess}->{user},'action','ipaction') && defined ${chr(ord("\026") << 2)} )
                  ? (
                        "<span onclick=\"popIPAction('"
                      . &normHTML($tConFno{$key}->{ip})
                      . "');\" onmouseover=\"linkBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=linkBG;\"><b>"
                      . $tConFno{$key}->{ip}
                      . "<\/b><\/span>"
                    )
                  :
                      $tConFno{$key}->{ip}
                  )

                  . "</td><td $bgcolor>"
                  . substr( $tConFno{$key}->{helo}, 0, 25 )
                  . "</td><td $bgcolor>" .

                  (
                  (! ($tConFno{$key}->{relayok} || $tConFno{$key}->{isreport}) && &canUserDo($WebIP{$ActWebSess}->{user},'action','addraction') && defined ${chr(ord("\026") << 2)} )
                  ? (
                        "<span onclick=\"popAddressAction('"
                      . &encHTMLent($tConFno{$key}->{mailfrom})
                      . "');\" onmouseover=\"linkBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=linkBG;\"><b>"
                      . substr( $tConFno{$key}->{mailfrom}, 0, 25 )
                      . "<\/b><\/span>"
                    )
                  :
                      substr( $tConFno{$key}->{mailfrom}, 0, 25 )
                  )

                  . "</td><td $bgcolor>"
                  . substr( $tConFno{$key}->{rcpt}, 0, 25 )
                  . "</td><td $bgcolor>"
                  . $tConFno{$key}->{lastcmd}
                  . "</td><td $bgcolor>"
                  . $relay
                  . "</td><td $bgcolor>"
                  . (($tConFno{$key}->{spamfound}) ? 'yes' : 'no') . ' / ' . $tConFno{$key}->{messagescore}
                  . "</td><td $bgcolor>"
                  . $tConFno{$key}->{maillength}
                  . "</td><td $bgcolor>"
                  . $tmpDuration
                  . "</td><td $bgcolor>"
                  . $tmpInactive.$damping
                  . '</td></tr>';
        }

#  <meta http-equiv="refresh" content="$refresh;url=/shutdown_list$query" />

# window.onfocus="tStart();" window.onblur="tStop();"
#   <meta http-equiv="refresh" content="$refresh;url=/shutdown_list$query" />
# onFocus="javascript:Stop();" onBlur="javascript:Start();"
$showcolor = $showcolor ? 'color-off' : 'color-on';
$showreports = $showreports ? 'reports-off' : 'reports-on';
my $ctime = localtime();
    <<EOT;
$headerHTTP
$headerDTDTransitional
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  $focusJS
  <title>$currentPage SPAMBOX ($myName) this monitor will slow down SPAMBOX dramaticly - use it careful</title>
  <link rel=\"stylesheet\" href=\"get?file=images/assp.css\" type=\"text/css\" />
</head>
<body onfocus="tStart();" onblur="tStop();">
<div id="cfgdiv">
<div style="float: right">$ctime
\&nbsp;\&nbsp;
refresh:\&nbsp;<input id="refreshtime" name="refreshtime" size="1" value="$refreshtime" onchange="javascript:switchtime();" onclick="javascript:startstop();"/>s
\&nbsp;\&nbsp;
<input id="reportsbutton" type="button" value="$showreports" onclick="javascript:switchreports();"/>
\&nbsp;\&nbsp;
<input id="colorbutton" type="button" value="$showcolor" onclick="javascript:switchcolor();"/>
\&nbsp;\&nbsp;
<input id="stasto" type="button" value="Stop" onclick="javascript:startstop();"/>
\&nbsp;\&nbsp;
<input id="print" type="button" value="print" onclick="javascript:processPrint();"/>
\&nbsp;\&nbsp;
<input type="button" value="Close" onclick="javascript:window.close();"/>
</div>
<h2>SMTP Connections List</h2>
$s1
<table cellspacing="0" id="conTable">
$s2
</table>
<br />
</div>
</body></html>
EOT
}
