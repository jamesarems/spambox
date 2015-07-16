#line 1 "sub main::Shutdown"
package main; sub Shutdown {
my $h1 = $WebIP{$ActWebSess}->{lng}->{'msg500070'} || $lngmsg{'msg500070'};

<<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2>ASSP Shutdown/Restart</h2>
<div class="note">
$h1
</div>
<br />
<table style="background-color: white; border-width: 0px; width: 500px">
<tr>
<td style="background-color: white; padding: 0px;">
<iframe src="/shutdown_frame" width="100%" height="300" frameborder="0" marginwidth="0" marginheight="0" scrolling="no"></iframe>
</td>
</tr>
</table>

</div>
$footers
</body></html>
EOT
}
