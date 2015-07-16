#line 1 "sub main::CheckRcptRepl"
package main; sub CheckRcptRepl {
 my $RecReprecipient = $qs{RecReprecipient};
 my $RecRepsender = $qs{RecRepsender};
 my $RecRepresult = '';
 my @RecRepresult;
 my $RecRepdspres = '';
 my $RecRepbutton;
 my $disabled = '';
 my $link_to_RecRep_config = $WebIP{$ActWebSess}->{lng}->{'msg500040'} || $lngmsg{'msg500040'};

 my $updres;
 my $file;

 if ($ReplaceRecpt =~ /^ *file: *(.+)/io) {
    $file=$1; $file="$base/$file" if $file!~/^\Q$base\E/io;
    if ( $FileUpdate{$file} != ftime($file) ) {
      $updres = configChangeRcptRepl('ReplaceRecpt',$ReplaceRecpt,$ReplaceRecpt,0);
    }
 }

 if ($ReplaceRecpt) {
   if ($qs{B1} =~ /Check/o){
       @RecRepresult = RcptReplace($RecReprecipient,$RecRepsender,'RecRepRegex');
       if ($updres) {
          $RecRepresult = $RecRepresult[0];
          $RecRepresult[0] = $updres;
       } else {
          $RecRepresult = shift(@RecRepresult);
       }
   }
   $RecRepbutton ='
    <tr>
        <td class="noBorder">&nbsp;</td>
        <td class="noBorder"><input type="submit" name="B1" value="  Check  " /></td>
        <td class="noBorder">&nbsp;</td>
    </tr>';
   foreach (@RecRepresult) {
     next if ($_ eq '1' || $_ eq '0');
     s/configuration$/ file $file/ if ($file);
     $RecRepdspres .= "$_\<br /\>";
   }
 } else {
   @RecRepresult = ();
   push (@RecRepresult, $WebIP{$ActWebSess}->{lng}->{'msg500041'} || $lngmsg{'msg500041'});
   $disabled = "disabled";
 }

 if ($ReplaceRecpt =~ /^ *file: *(.+)/io) {
  $file = $1;
  if ($file) {
    $link_to_RecRep_config = $WebIP{$ActWebSess}->{lng}->{'msg500042'} || $lngmsg{'msg500042'};
    $link_to_RecRep_config .= $file.' &nbsp;<input type="button" value="Edit" onclick="javascript:popFileEditor(\''.$file.'\',3);" /></p>';
  }
 }
 my $h1 = $WebIP{$ActWebSess}->{lng}->{'msg500043'} || $lngmsg{'msg500043'};

<<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2>recipient replacement test</h2>
<div class="textBox">
$link_to_RecRep_config
</div>
<form method="post" action=\"\">
    <table class="textBox" style="width: 99%;">
        <tr>
            <td class="noBorder">recipient : </td>
            <td class="noBorder">
            <input type="text" $disabled size="30" name="RecReprecipient" value="$RecReprecipient"</td>
        </tr>
        <tr>
            <td class="noBorder">sender    : </td>
            <td class="noBorder">
            <input type="text" $disabled size="30"  name="RecRepsender" value="$RecRepsender"</td>
        </tr>
        <tr><td class="noBorder">  </td></tr>
        <tr>
            <td class="noBorder">result    : </td>
            <td class="noBorder">
            <p>$RecRepresult</p></td>
        </tr>
        $RecRepbutton
    </table>
</form>
<div class="textBox">
$h1
$RecRepdspres
</form>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
  <input name="theButtonLogout" type="hidden" value="" />
</form>
</div>
</div>
$footers
</body></html>
EOT

}
