#line 1 "sub main::ShutdownFrame"
package main; sub ShutdownFrame {
 my $action=$qs{action};
 my ($s1,$s2,$editButtons,$query,$refresh);
 my $shutdownDelay=2;

 my $timerJS='
<script type="text/javascript">
  var ns=(navigator.appName.indexOf("Netscape")!=-1);
  var timerVal=parseInt(ns ? document.getElementById("myTimer1").childNodes[0].nodeValue : myTimer1.innerText);
  function countDown() {
    if (isNaN(timerVal)==0 && timerVal>=0) {
      if (ns) {
        document.getElementById("myTimer1").childNodes[0].nodeValue=timerVal--;
      } else {
        myTimer1.innerText=timerVal--;
      }
      setTimeout("countDown()",1000);
    }
  }
  countDown();
</script>';
if ($action=~/abort/io) {
  $shuttingDown=0;
  $refresh=3;
  $s1='Shutdown request aborted';
  $editButtons='<input type="submit" name="action" value=" Proceed " disabled="disabled" />&nbsp;
<input type="submit" name="action" value=" Abort " disabled="disabled" />';
  $doShutdown=0;
  $query='?nocache='.time;
  mlog(0,"shutdown/restart process aborted per admin request; SMTP session count:$smtpConcurrentSessions");
 } elsif ($action=~/proceed/io || $shuttingDown) {
  $shuttingDown=1;
  $refresh=$smtpConcurrentSessions>0 ? 2 : 90;
  $s1=$smtpConcurrentSessions>0 ? 'Waiting for '. needEs($smtpConcurrentSessions,' SMTP session','s') .' to finish ...' : "Shutdown in progress, please wait: <span id=\"myTimer1\">$refresh</span>s$timerJS";
  $editButtons='<input type="submit" name="action" value=" Proceed " disabled="disabled" />&nbsp;
<input type="submit" name="action" value=" Abort "'.($smtpConcurrentSessions>0 ? '' : ' disabled="disabled"').' />
'.($refresh>1 ? '' : '&nbsp;<input type="button" name="action" value=" View " onclick="javascript:window.open(\'shutdown_list?\',\'SMTP_Connections\',\'width=600,height=600,toolbar=no,menubar=no,location=no,personalbar=no,scrollbars=yes,status=no,directories=no,resizable=yes\')" />').'';


  $doShutdown=$smtpConcurrentSessions>0 ? 0 : time+$shutdownDelay;
  $query=$smtpConcurrentSessions>0 ? '?nocache='.time : '?action=Success';
  mlog(0,"shutdown/restart process initiated per admin request; SMTP session count:$smtpConcurrentSessions") if $action=~/proceed/i;
 } elsif ($action=~/success/io) {
  $refresh=3;
  $s1='ASSP restarted successfully.';
  $editButtons='<input type="submit" name="action" value=" Proceed " disabled="disabled" />&nbsp;
<input type="submit" name="action" value=" Abort " disabled="disabled" />';
  $doShutdown=0;
  $query='?nocache='.time;
 } else {
  $refresh=1;

  $s1=$smtpConcurrentSessions>0 ? ($smtpConcurrentSessions>1 ? 'There are ' : 'There is '). needEs($smtpConcurrentSessions,' SMTP session','s') .' active' : 'There are no active SMTP sessions';
  $editButtons='<input type="submit" name="action" value=" Proceed " />&nbsp;
<input type="submit" name="action" value=" Abort " disabled="disabled" />&nbsp;
<input type="button" name="action" value=" View " onclick="javascript:window.open(\'shutdown_list?\',\'SMTP_Connections\',\'width=600,height=600,toolbar=no,menubar=no,location=no,personalbar=no,scrollbars=yes,status=no,directories=no,resizable=yes\')" />';
  $doShutdown=0;
  $query='?nocache='.time;
 }
  my $quit; $quit = '<form action="quit" method="post">
<table class="textBox" style="width: 99%;">
  <tr><td class="noBorder" align="center">Panic button:</td></tr>
  <tr><td class="noBorder" align="center"><input type="submit" value="Terminate ASSP now!" /></td></tr>
</table>
</form>' unless $AsAService;
my $bod = $action=~/success/io ? '<body onload="top.location.href=\'/#\'">' : '<body>' ;
<<EOT;
$headerHTTP
$headerDTDTransitional
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <meta http-equiv="refresh" content="$refresh;url=/shutdown_frame$query" />
  <title>$currentPage ASSP ($myName)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/shutdown.css\" type=\"text/css\" />
</head>
$bod
<div id="cfgdiv" class="content">
<form action="" method="get">
  <table class="textBox">
    <tr>
      <td class="noBorder" nowrap>
        $editButtons&nbsp;&nbsp;&nbsp;$s1
      </td>
    </tr>
  </table>
</form>
</div>
<div class="content">

$quit
</div>
</body></html>
EOT
}
