#line 1 "sub main::webConfig"
package main; sub webConfig{
 my $r = '';
 my $tmp;
 $ConfigChanged = 0;
 %LDAPNotFound = ();
 # don't post partial data if somebody's browser's busted
 undef %qs unless $qs{theButton} || $qs{theButtonX};
 undef %qs if $qs{theButtonRefresh};
 my $counter = 0;
 my @tmp;
 $headerTOC = "\n<table style=\"margin-left:2cm; text-align:left;\" CELLSPACING=0 CELLPADDING=0>
<tr><th>Table of Contents: </th></tr>
<tr style=\"margin-left:3cm;\"><td>&nbsp;</td></tr>
";
 &niceConfig();
 for my $idx (0...$#ConfigArray) {
  my $c = $ConfigArray[$idx];
  if (@{$c} == 5){
   # Is a header
   @tmp = @{$c};
   push(@tmp, "setupItem$counter");
   $r .= $c->[3]->(@tmp);
   $counter++;
   &MainLoop1(0) unless $counter % 4;
  }
  else {
   # Is a variable
   $r .= $c->[3]->(@{$c});
  }
 }
 $headerTOC .= "</table>\n";
 if (exists $WebIP{$ActWebSess}->{changedLang}) {
     $headerTOC =~ s/<a\s+href.*<\/a>//iog;
     $headerTOC =~ s/(["\/]|\r?\n)/\\$1/gos;
 }
 if($ConfigChanged or $WebIP{$ActWebSess}->{changedLang}){
  renderConfigHTML();
  PrintConfigSettings();
  $WebIP{$ActWebSess}->{changedLang} = 0;
 }
my $regexp1='';
my $regexp2='';
my $rs = ($allIdle > 0 ? 'resume' : 'suspend');
my $reload  =
'
<table class="textBox" style="width: 99%;">
 <tr>
     <td class="noBorder" align="left">Load Config From Disk:</td><td class="noBorder" align="center">Suspend or Resume:</td><td class="noBorder" align="right">Panic Button:</td>
 </tr>
 <tr>
     <form action="reload" method="post"><td class="noBorder" align="left"><input type="submit" value="Load Config" /></td></form>
     <form action="suspendresume" method="post"><td class="noBorder" align="center"><input type="submit" value="'.$rs.'" /></td></form>
     <form action="quit" method="post"><td class="noBorder" align="right"><input type="submit" value="Terminate Now!" /></td></form>
 </tr>
</table>
';
#$regexp1 = $WebIP{$ActWebSess}->{lng}->{'msg500011'} || $lngmsg{'msg500011'} if !$CanMatchCIDR;
#$regexp2 = $WebIP{$ActWebSess}->{lng}->{'msg500012'} || $lngmsg{'msg500012'} if !$CanMatchCIDR;
$regexp1 = $WebIP{$ActWebSess}->{lng}->{'msg500013'} || $lngmsg{'msg500013'};
$regexp2 = $WebIP{$ActWebSess}->{lng}->{'msg500014'} || $lngmsg{'msg500014'};
my $cidr='';

$cidr = $WebIP{$ActWebSess}->{lng}->{'msg500015'} || $lngmsg{'msg500015'} if !$CanUseCIDRlite;
$cidr = $WebIP{$ActWebSess}->{lng}->{'msg500016'} || $lngmsg{'msg500016'} if $CanUseCIDRlite;
  my $quit; $quit = '<form action="quit" method="post">
<table class="textBox" style="width: 99%;">
  <tr><td class="noBorder" align="center">Panic button: </td></tr>
  <tr><td class="noBorder" align="center"><input type="submit" value="Terminate Now!" /></td></tr>
</table>
</form>' unless $AsAService;

my $currStat = &StatusSPAMBOX();
$currStat = ($currStat =~ /not healthy/io)
   ? '<a href="./statusspambox" target="blank" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>SPAMBOX '.$version.$modversion.($codename?" ( code name $codename )":'').' is running not healthy! Click to show the current detail thread status.</td></tr></table>\', this, event, \'450px\', \'\'); return true;"><b><font color=\'red\'>&bull;</font></b></a>'
   : '<a href="./statusspambox" target="blank" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>SPAMBOX '.$version.$modversion.($codename?" ( code name $codename )":'').' is running healthy. Click to show the current detail thread status.</td></tr></table>\', this, event, \'450px\', \'\'); return true;"><font color=#66CC66>&bull;</font></a>';

 my $lFoptions = "<option value=\"default\">default</option>";
 my @DIR = Glob("$base/language/*");
 while (@DIR) {
     $_ = shift @DIR;
     my $sel = '';
     next if /[\/\\]spambox\.lng$/oi;
     next if /[\/\\]readme\.txt$/oi;
     next if /[\/\\]default_en_msg_[^\/\\]+$/oi;
     s/\Q$base\E\/language\///oi;
     $sel = "selected=\"selected\"" if $_ eq $qs{languageFile};
     $lFoptions .= "<option $sel value=\"$_\">$_</option>";
 }
 my $sellang = "<hr /><div style=\"text-align: center;\"><b>select a language file to change the display language</b><br /><br />";
 $sellang .= "
 <span style=\"z-Index:100;\"><select size=\"1\" name=\"languageFile\">
 $lFoptions
 </select></span>

    &nbsp;<input type=\"button\" value=\"edit\" onclick=\"javascript:popFileEditor('language/'+(document.forms['SPAMBOXconfig'].languageFile.value=='default' || document.forms['SPAMBOXconfig'].languageFile.value=='' ? 'spambox.lng' : document.forms['SPAMBOXconfig'].languageFile.value),1);
    \" /><br />
    &nbsp;<input type=\"button\" value=\"readme\" onclick=\"javascript:popFileEditor('language/readme.txt',1);\" />
    </div><hr />
 ";

my $blocking;
if (exists $WebIP{$ActWebSess}->{blocking}) {
   $blocking = $WebIP{$ActWebSess}->{blocking} ? ' -blocking' : ' -nonblocking';
}
my $networkatt = ($DisableSMTPNetworking && $allIdle >= 0) ? ' <a href="./#DisableSMTPNetworking" onmousedown="expand(0, 1);showDisp(\''.$ConfigPos{DisableSMTPNetworking}.'\');"><font color="#CC0000">SMTP networking is disabled!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</font></a>' : '';
my $runas = $AsAService ? ($allIdle > 0 ? ' (as service - suspended)' : ' (as service)') : ($AsADaemon ? ($allIdle > 0 ? ' (as daemon - suspended)' : ' (as daemon)') : ($allIdle > 0 ? ' (console mode - suspended)' : ' (console mode)'));
my $pathhint = $^O eq 'MSWin32' ? $WebIP{$ActWebSess}->{lng}->{'msg500017'} || $lngmsg{'msg500017'} : '';
my $mainhint = $WebIP{$ActWebSess}->{lng}->{'msg500018'} || $lngmsg{'msg500018'};
my $killhint = $WebIP{$ActWebSess}->{lng}->{'msg500019'} || $lngmsg{'msg500019'};
$mainhint = $regexp1 = $regexp2 = $cidr = $pathhint = '' if $mobile;
my $fullCFG = $mobile ? "margin:5px 0 0 0;" : '';
my $fullCFG2 = $mobile ? " style=\"margin:5px 0 0 0;\"" : '';

<<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgh2" class="content"$fullCFG2>
<h2>$currStat SPAMBOX$runas - Configuration ($WebIP{$ActWebSess}->{user}$blocking)$networkatt</h2>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
</div>
<script type="text/javascript">
<!--
var cfgdivHeight = ClientSize('h') - document.getElementById('TopMenu').offsetHeight - (document.getElementById('cfgh2').offsetHeight * 2) + 'px';
// -->
</script>
<div id="cfgdiv" class="content" style="display:block;height:800px;overflow-y:auto;$fullCFG">
<script type="text/javascript">
<!--
document.getElementById('cfgdiv').style.height = cfgdivHeight;
// -->
</script>
<div>
$r
</div>
<div class="rightButton">
$sellang
</div>
</div>
<div class="rightButton">
  <input name="theButton" type="submit" value="Apply Changes" onclick="WaitDiv();"/>
  <input name="theButtonX" type="hidden" value="" />
  <input name="theButtonRefresh" type="hidden" value="" />
  <input name="theButtonLogout" type="hidden" value="" />
</div>
<div class="content">
<div id="mainhints" class="note">
$pathhint
$mainhint $regexp1 $cidr $regexp2

$killhint
</div>
</form>
$reload

<br />
$kudos
<br />
</div>
$footers
<script type="text/javascript">
<!--
  expand(0, 0);
  string = new String(document.location);
  string = string.substr(string.indexOf('#')+1);
  if(document.forms[0].length) {
    for(i = 0; i < document.forms[0].elements.length; i++) {
      if(string == document.forms[0].elements[i].name) {
        document.forms[0].elements[i].focus();
      }
    }
  }
  initAnchor('$RememberGUIPos');
// -->
</script>
</body></html>
EOT
}
