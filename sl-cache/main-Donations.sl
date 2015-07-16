#line 1 "sub main::Donations"
package main; sub Donations {
<<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2>SPAMBOX Donations</h2>
<div class="note">
SPAMBOX is here thanks to the following people, please feel free to donate to support the SPAMBOX project.
</div>
<br />
<table style="width: 99%;" class="textBox">
<tr>
<td class="underline">John Hanna the founder and developer of SPAMBOX up to version 1.0.12</td>
<td class="underline">&nbsp;</td>
</tr>
<tr>
<td class="underline">John Calvi the developer of SPAMBOX from version 1.0.12.</td>
<td class="underline">&nbsp;</td>
</tr>
<tr>
<td class="underline">Fritz Borgstedt &dagger; the developer of SPAMBOX V1 since 1.2.0</td>
<td class="underline">&nbsp;</td>
</tr>
<tr>
<td class="underline">Thomas Eckardt the developer of SPAMBOX V2 since 2.0.0</td>
<td class="underline"><a href="https://www.paypal.com/xclick/business=Thomas.Eckardt%40thockar.com&amp;item_name=Support+SPAMBOX&amp;item_number=assp&amp;no_note=1&amp;tax=0&amp;currency_code=USD" rel="external">Donate via Paypal</a></td>
</tr>
<tr>
<td class="underline">bitcoins are also welcome</td>
<td class="underline">15ekjW9grtT7WTUFMcfbmokwoomZCYeMKr</td>
</tr>
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>
<tr>
<td colspan="2">
<div class="note">Special thanks go to......<br />
&nbsp;&nbsp;  Nigel Barling, AJ, Robert Orso, Przemek Czerkas, Mark Pizzolato,<br />
&nbsp;&nbsp;  Wim Borghs, Micheal Espinola, Doug Traylor, Lars Troen,<br />
&nbsp;&nbsp;  Andrew Macpherson, Javier Albinarrate for their contributions in 1.2.x.<br />

</div>
</td>
</tr>
</table>
<br />
$kudos
<br />
</div>
$footers
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
  <input name="theButtonLogout" type="hidden" value="" />
</form>
</body></html>
EOT
}
