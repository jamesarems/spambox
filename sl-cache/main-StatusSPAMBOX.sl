#line 1 "sub main::StatusSPAMBOX"
package main; sub StatusSPAMBOX {
     my %status = &WorkerStatus();
     my $refresh = 5;
     my $query = '?nocache='.time;
     my $s1;
     my $tmpCount = 0;
     my $rowclass;
     my $healthy = 'SPAMBOX Worker/DB/Regex Status - <span class="positive">healthy</span>';
     
     $s1 = "<tr><td class=\"conTabletitle\">Worker</td><td class=\"conTabletitle\">loop age</td><td class=\"conTabletitle\">current action</td></tr>";

     foreach my $s (sort {$main::a <=> $main::b } keys %status) {
         $tmpCount++;
         if ($tmpCount%2==1) {
             $rowclass = "\n<tr>";
         } else {
             $rowclass = "\n<tr class=\"even\">";
         }
         $s1 .= $rowclass;
         $s1 .= "<td><b>$s</b></td>";
         if ($s < 10000) {
             if ($status{$s}{lastloop} < 180) {
                 $s1 .= "<td>$status{$s}{lastloop} s</td>";
                 $s1 .= "<td>$status{$s}{lastaction}</td>";
             } else {
                 $s1 .= "<td><span class=\"negative\">$status{$s}{lastloop} s</span></td>";
                 $s1 .= "<td><span class=\"negative\">$status{$s}{lastaction} (stuck)</span></td>";
                 $healthy = 'SPAMBOX Worker/DB/Regex Status - <span class="negative">not healthy</span>';
             }
         } else {
             $s1 .= "<td>$status{$s}{lastloop} s</td>";
             $s1 .= "<td>$status{$s}{lastaction}</td>";
         }
         $s1 .= "</tr>";
     }
     
     my $s2 = "<tr><td class=\"conTabletitle\">failed database tables - local files are used for:</td></tr>";
     $tmpCount = 0;
     foreach my $s (keys %failedTable) {
         next if $failedTable{$s} < 2;
         $tmpCount++;
         if ($tmpCount%2==1) {
             $rowclass = "\n<tr>";
         } else {
             $rowclass = "\n<tr class=\"even\">";
         }
         $s2 .= $rowclass;
         $s2 .= "<td><span class=\"negative\"><b>$s</b></span></td>";
         $s2 .= "</tr>";
         $healthy = 'SPAMBOX Worker/DB/Regex Status - <span class="negative">not healthy</span>';
     }
     if (! $tmpCount) {
         $s2 .= "<tr><td><span class=\"positive\"><b>no failed database tables</b></span></td></tr>";
     }

     my $s21 = "<tr><td class=\"conTabletitle\">database version check:</td></tr>";
     $tmpCount = 0;
     if (! ($ignoreDBVersionMissMatch & 1) && $DoBayesian && $haveSpamdb && $currentDBVersion{Spamdb} ne $requiredDBVersion{Spamdb}) {
         $tmpCount++;
         if ($tmpCount%2==1) {
             $rowclass = "\n<tr>";
         } else {
             $rowclass = "\n<tr class=\"even\">";
         }
         $s21 .= $rowclass;
         $s21 .= "<td><span class=\"negative\"><b>Spamdb</b></span> has version: <b>$currentDBVersion{Spamdb}</b> - required version: <b>$requiredDBVersion{Spamdb}</b> ! Run a rebuildspamdb to correct this!</td>";
         $s21 .= "</tr>";
         $healthy = 'SPAMBOX Worker/DB/Regex Status - <span class="negative">not healthy</span>';
     }
     if (! ($ignoreDBVersionMissMatch & 2) && $DoHMM && $haveHMM && $currentDBVersion{HMMdb} ne $requiredDBVersion{HMMdb}) {
         $tmpCount++;
         if ($tmpCount%2==1) {
             $rowclass = "\n<tr>";
         } else {
             $rowclass = "\n<tr class=\"even\">";
         }
         $s21 .= $rowclass;
         $s21 .= "<td><span class=\"negative\"><b>HMMdb</b></span> has version: <b>$currentDBVersion{HMMdb}</b> - required version: <b>$requiredDBVersion{HMMdb}</b> ! Run a rebuildspamdb to correct this!</td>";
         $s21 .= "</tr>";
         $healthy = 'SPAMBOX Worker/DB/Regex Status - <span class="negative">not healthy</span>';
     }
     if (! $tmpCount) {
         $s21 .= "<tr><td><span class=\"positive\"><b>no database version missmatch found</b></span></td></tr>";
     }

     my $s3 = "<tr><td class=\"conTabletitle\">failed regular expressions:</td></tr>";
     $tmpCount = 0;
     if (scalar keys %RegexError) {
         foreach my $s (keys %RegexError) {
             if ($tmpCount%2==1) {
                 $rowclass = "\n<tr>";
             } else {
                 $rowclass = "\n<tr class=\"even\">";
             }
             $s3 .= $rowclass;
             $s3 .= "<td><span class=\"negative\"><b>$s : $RegexError{$s}</b></span></td>";
             $s3 .= "</tr>";
         }
         $healthy = 'SPAMBOX Worker/DB/Regex Status - <span class="negative">not healthy</span>';
     } else {
         $s3 .= "<tr><td><span class=\"positive\"><b>no failed regular expressions</b></span></td></tr>";
     }
     my $focusJS = '
<script type="text/javascript">
//noprint
 Timer=setTimeout("newTimer();", 5000);
 var Run = 1;
 function noop () {}
 function tStart () {
    Run = 1;
 }
 function tStop () {
    Run = 0;
    Timer=setTimeout("noop();", 1000);
 }
 var Run2 = 1;
 function startstop() {
     Run2 = (Run2 == 1) ? 0 : 1;
     document.getElementById(\'stasto\').value = (Run2 == 1) ? "Stop" : "Start";
 }
 function newTimer() {
   if (Run == 1 && Run2 == 1) {location.reload();}
   Timer=setTimeout("newTimer();", 5000);
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
#  <meta http-equiv="refresh" content="$refresh;url=/statusassp$query" />

<<EOT;
$headerHTTP
$headerDTDTransitional
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  $focusJS
  <title>$currentPage SPAMBOX ($myName) Worker/DB/Regex Status</title>
  <link rel=\"stylesheet\" href=\"get?file=images/assp.css\" type=\"text/css\" />
</head>
<body onfocus="tStart();" onblur="tStop();">
<div id="cfgdiv">
<div style="float: right">
<input id="print" type="button" value="print" onclick="javascript:processPrint();"/>
\&nbsp;\&nbsp;
<input id="stasto" type="button" value="Stop" onclick="javascript:startstop();"/>
\&nbsp;\&nbsp;
<input type="button" value="Close" onclick="javascript:window.close();"/></div>
<h2>$healthy</h2>
<br />
<table cellspacing="0" id="conTable">
$s1
</table>
<br />
<br />
<table cellspacing="0" id="conTable">
$s2
</table>
<br />
<br />
<table cellspacing="0" id="conTable">
$s21
</table>
<br />
<br />
<table cellspacing="0" id="conTable">
$s3
</table>
<br />
</div>
</body></html>
EOT

}
