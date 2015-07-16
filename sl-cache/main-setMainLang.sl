#line 1 "sub main::setMainLang"
package main; sub setMainLang {

$lngmsghint{'msg500011'} = '# main form buttom hint 1';
$lngmsg{'msg500011'} = 'The CIDR notation is allowed(182.82.10.0/24).';

$lngmsghint{'msg500012'} = '# main form buttom hint 2';
$lngmsg{'msg500012'} = '<br />Text after the range (and before a number sign) will be accepted as comment which will be shown in a match (for example: 182.82.10.0/24 Yahoo Groups #comment not shown).' ;

$lngmsghint{'msg500013'} = '# main form buttom hint 3';
$lngmsg{'msg500013'} = 'CIDR notation is accepted (182.82.10.0/24).' ;

$lngmsghint{'msg500014'} = '# main form buttom hint 4';
$lngmsg{'msg500014'} = '<br />Text after the range (and before a number sign) will be accepted as comment to be shown in a match. For example:<br />182.82.10.0/24 Yahoo #comment to be removed<br />The short notation like 182.82.10. is only allowed for IPv4 addresses, IPv6 addresses must be fully defined as for example 2201:1::1 or 2201:1::/96<br />You may define a hostname instead of an IP, in this case the hostname will be replaced by all DNS-resolved IP-addresses, each with a /32 or /128 netmask. For example:<br />mta5.am0.yahoodns.net Yahoo #comment to be removed -&gt; 66.94.238.147/32 Yahoo|... Yahoo|... Yahoo<br />' ;

$lngmsghint{'msg500015'} = '# main form buttom hint 5';
$lngmsg{'msg500015'} = 'If Net::CIDR::Lite is installed, hyphenated ranges can be used (182.82.10.0-182.82.10.255).';

$lngmsghint{'msg500016'} = '# main form buttom hint 6';
$lngmsg{'msg500016'} = 'Hyphenated ranges can be used (182.82.10.0-182.82.10.255).';

$lngmsghint{'msg500017'} = '# main form buttom hint 7';
$lngmsg{'msg500017'} = 'For defining any full filepaths, always use slashes ("/") not backslashes. For example: c:/spambox/certs/server-key.pem !<br /><br />';

$lngmsghint{'msg500018'} = '# main form buttom hint 8';
$lngmsg{'msg500018'} = <<EOT;
Fields marked with one small (<sup>s</sup>) - which are interval definitions - accept a single or a list of crontab entries separated by '|'. Such entries could be used to flexible schedule the configured task. A description of such crontab entries could be found in 'RebuildSchedule' and 'RestartSchedule'. Notice - this requires an installed <a href="http://search.cpan.org/search?query=Schedule::Cron" rel="external">Schedule::Cron</a> module in PERL.<br /><br />
Fields marked with at least one asterisk (*) accept a list separated by '|' (for example: abc|def|ghi) or a file designated as follows (path relative to the SPAMBOX directory): 'file:files/filename.txt'.  Putting in the <i>file:</i> will prompt SPAMBOX to put up a button to edit that file. <i>files</i> is the subdirectory for files. The file does not need to exist, you can create it by saving it from the editor within the UI. The file must have one entry per line; anything on a line following a number sign or a semicolon ( # ;) is ignored (a comment).<br />
It is possible to include custom-designed files at any line of such a file, using the following directive<br />
<span class="positive"># include filename</span><br />
where filename is the relative path (from $base) to the included file like files/inc1.txt or inc1.txt (one file per line). The line will be internaly replaced by the contents of the included file!<br /><br />
Fields marked with two asterisk (**) contains regular expressions (regex) and accept a second weight value. Every weighted regex that contains at least one '|' has to begin and end with a '~' - inside such regexes it is not allowed to use a tilde '~', even it is escaped - for example:  ~abc<span class="negative"><b>\\~</b></span>|def~=>23 or ~abc<span class="negative"><b>~</b></span>|def~=>23 - instead use the octal (\\126) or hex (\\x7E) notation , for example <span class="positive">~abc\\126|def~=>23 or ~abc\\x7E|def~=>23</span> . Every weighted regex has to be followed by '=>' and the weight value. For example: Phishing\\.=>1.45|~Heuristics|Email~=>50  or  ~(Email|HTML|Sanesecurity)\\.(Phishing|Spear|(Spam|Scam)[a-z0-9]?)\\.~=>4.6|Spam=>1.1|~Spear|Scam~=>2.1 . The multiplication result of the weight and the penaltybox valence value will be used for scoring, if the absolute value of weight is less or equal 6. Otherwise the value of weight is used for scoring. It is possible to define negative values to reduce the resulting message score.<br />
For all "<span class="positive">bomb*</span>" regular expressions and "<span class="positive">invalidFormatHeloRe</span>", "<span class="positive">invalidPTRRe</span>" and "<span class="positive">invalidMsgIDRe</span>" it is possible to define a third parameter (to overwrite the default options) after the weight like: Phishing\\.=>1.45|~Heuristics|Email~=>50<span class="positive">:>N[+-]W[+-]L[+-]I[+-]</span>. The characters and the optional to use + and - have the following functions:<br />
use this regex (+ = only)(- = never) for: N = noprocessing , W = whitelisted , L = local , I = ISP mails . So the line ~Heuristics|Email~=>50:>N-W-LI could be read as: take the regex with a weight of 50, never scan noprocessing mails, never scan whitelisted mails, scan local mails and mails from ISP's (and all others). The line ~Heuristics|Email~=>3.2:>N-W+I could be read as: take the regex with a weight of 3.2 as factor, never scan noprocessing mails, scan only whitelisted mails even if they are received from an ISP .<br />
If the third parameter is not set or any of the N,W,L,I is not set, the default configuration for the option will be used unless a default option string is defined anywhere in a single line in the file in the form !!!NWLI!!! (with + or - is possible).<br />
<span class="negative">If any parameter that allowes the usage of weighted regular expressions is set to "block", but the sum of the resulting weighted penalty value is less than the corresponding "Penalty Box Valence Value" (because of lower weights) - only scoring will be done!</span><br />
If the regular expression optimization is used - ("perl module Regexp::Optimizer" installed and enabled) - and you want to disable the optimization for a special regular expression (file based), set one line (eg. the first one) to a value of '<span class="positive">spambox-do-not-optimize-regex</span>' or '<span class="positive">a-d-n-o-r</span>' (without the quotes)! To disable the optimization for a specific line/regex, put &lt;&lt;&lt; in front and &gt;&gt;&gt; at the end of the line/regex. To weight such line/regex write for example: <span class="positive">&lt;&lt;&lt;</span>Phishing\\.<span class="positive">&gt;&gt;&gt;</span>=>1.45=>N- or ~<span class="positive">&lt;&lt;&lt;</span>Heuristics|Email<span class="positive">&gt;&gt;&gt;</span>~=>50  or  ~<span class="positive">&lt;&lt;&lt;</span>(Email|HTML|Sanesecurity)\\.(Phishing|Spear|(Spam|Scam)[a-z0-9]?)\\.<span class="positive">&gt;&gt;&gt;</span>~=>4.6 .<br /><br />
The literal 'SESSIONID' will be replaced by the unique message logging ID in every SMTP error reply.<br />
The literal 'NOTSPAMTAG' will be replaced by a random calculated TAG using <a href="./NotSpamTag">NotSpamTag</a>, in every SMTP permanent (5xx) error reply.<br />
The literal 'MYNAME' will be replaced by the configuration value defined in 'myName' in every SMTP error reply.<br /><br />
If the internal name is shown in light blue like <span style="color:#8181F7">(uniqueIDPrefix)</span> , this indicates that the configured value differs from the default value. To show the default value, move the mouse over the internal name. A click on the internal name will reset the value to the default.<br /><br />
IP ranges are defined as for example 182.82.10.
EOT

$lngmsghint{'msg500019'} = '# main form buttom hint 9';
$lngmsg{'msg500019'} = <<EOT;
<br /><br />'kill -HUP $mypid' will load settings from disk. 'kill -NUM07 $mypid' will suspend or resume spambox.  'kill -USR2 $mypid' will save settings to disk.
EOT

$lngmsghint{'msg500020'} = '# manage users form hint';
$lngmsg{'msg500020'} = <<EOT;
Use the "Continue" button as long as you only want to see or to temporary change any parameter.
Use the "Apply Changes" button to apply all changes, that are currenty shown, to the user.
All user names that begins with a "~" are templates. The template "~DEFAULT" can't be deleted.
All permissions of a user can refer to a template, in this case the permission of the template
belongs to the user. If the template permission is changed, all user permissions
that refers to that template will also be changed. Template permissions can never refer to an
another user or template. It is possible to copy all permissions of a template or a user to
another user or template. If "use LDAP / LDAP host" is filled with an IP-address or hostname
the local password will only be used, if the LDAPhost is not available. If an LDAP login is
successful, the LDAP-password will be stored as local password. It is possible to configure
multiple LDAP hosts separated by "|". To navigate use the alpha-index on the left site.
EOT

$lngmsghint{'msg500031'} = '# White/Redlist/Tuplets';
$lngmsg{'msg500031'} = <<EOT;
Do you want to work with the:
EOT

$lngmsg{'msg500032'} = <<EOT;
Do you want to:
EOT

$lngmsg{'msg500033'} = <<EOT;
<p>Post less than 1 megabyte of data at a time.</p>
Note: The redlist is not a blacklist. The redlist is a list of addresses that cannot
contribute to the whitelist, and who are not considered local, even if their mail is
from a local computer. For example, if someone goes on a vacation and turns on their
email's autoresponder, put them on the redlist until they return. Then as they reply
to every spam they receive they won't corrupt your non-spam collection or whitelist.<br />
To add or remove global whitelist entries use emailaddress,* .<br />
To add or remove domain whitelist entries use emailaddress,\@domain .<br />
<b>NOTICE: removing global or domain whitelist entries will DELETE ALL related personal records!</b>
EOT

$lngmsg{'msg500034'} = <<EOT;
<p class="warning">Warning: If your whitelist or redlist is long, pushing these buttons
 is ill-advised. Use these for testing and while your whitelist is short.</p>
EOT

$lngmsghint{'msg500040'} = '# Recipient Replacement Test';
$lngmsg{'msg500040'} = '<p><a href="./#ReplaceRecpt">go to ReplaceRecpt to configure rules</a></p>';
$lngmsg{'msg500041'} = '<p><span class="negative"><a href="./#ReplaceRecpt">ReplaceRecpt</a> is not configured - please do this first!</span></p>';
$lngmsg{'msg500042'} = '<p>to modify the replacement rules, open the file by clicking edit ';

$lngmsg{'msg500043'} = '<p>the following replacement rules were processed (matching rules are shown green)</p><br />';

$lngmsghint{'msg500050'} = '# View Maillog Tail';
$lngmsg{'msg500050'} = <<EOT;
Refresh your browser or click [Search/Update] to update this screen. Newest entries are at the end. The search will stop, if the [search for] field is blank - and [tail bytes] is reached, or if the [search for] field is not blank - and [search in] or the number of [results] is reached. If you search for more than one word, all words must match. Words with a leading \\'-\\' will be negated. For example: a search pattern \\'user -root\\', will search all lines which contains the word \\'user\\' but not the word \\'root\\'! Don\\'t use the characters &quot;&gt;\\'&lt;&amp; in the search field.
EOT

$lngmsg{'msg500051'} = <<EOT;
Select [file lines only], if you want to reduce the shown number of lines to such (POST filter), which contains filenames.<br /><br /> Use the MaillogTail function carefully, while SPAMBOX is processing any request, no new connections will be accepted by SPAMBOX, and this could take some minutes, if you search in large or many maillogs! To start realtime maillog, click on [Auto], to stop realtime maillog, click on [Stop].
EOT

$lngmsg{'msg500052'} = <<EOT;
If [this file number(s)] is selected, you can define a single filenumber or a comma separated list of filenumbers here - like: <b>1,5,8,7,6 or 10,2...7,11,14-19,21,23...26</b>  A defined range 2...7 or 2-7 will include all numbers from 2 to 7. The resulting numbers will be internaly sorted ascending and the files will be used in that sorted order.
EOT

$lngmsg{'msg500053'} = <<EOT;
Enter the search string - for more help use the [help] link. If you want to start the realtime log [Auto], you can define the number of lines to show in the browser [1 - 33] here.
EOT

$lngmsghint{'msg500060'} = '# Mail Analyzer';
$lngmsg{'msg500060'} = <<EOT;
This page will show you how SPAMBOX analyzes and pre-processes an email to come up with the assigned spam probability. Regular Expressions will always check the full message. Group matching of any address will be shown. To analyze/modify individual email addresses click <a href="javascript:void(0);" onclick="popAddressAction('example\@$myName');return false;">here</a>. To analyze/modify individual IP addresses click <a href="javascript:void(0);" onclick="popIPAction('1.1.1.1');return false;">here</a>.
EOT

$lngmsg{'msg500061'} = <<EOT;
Copy and paste the mail header and body here:
EOT

$lngmsg{'msg500062'} = <<EOT;
<b>You may put here helo=aaa.bbb.helo or ip=123.123.123.123 to look up the helo/ip information. text=abc will start a lookup in the regular expression files for the "abc" matching regex.<br />
Put helo=domain.com and ip=123.123.123.123 in two lines, to lookup SPF results.</b>
<p>Note: Analysis is performed using the current spam database --
if yours was rebuilt since the time the mail was received you'll
receive a different result.</p>
EOT

$lngmsg{'msg500063'} = <<EOT;
<p>To use this form using <i>Outlook Express</i> do the following. Right-click on the message
of interest. Select <i>Properties</i>. Click the <i>Details</i> tab. Click the <i>message
source</i> button. Right-click on the message source and click <i>Select All</i>. Right-click
again and click <i>Copy</i>. Click on the text box above and paste (Ctrl-V perhaps). Click
the <i>Analyze</i> button.</p>
<p>The page will update to show you the following: if any of the email's addresses are in
the redlist or whitelist, the most and least spammy phrases together with their spaminess,
the resulting probabilities (probabilities may repeat one time), and the final spam probability
score.<br /><br />
To only transliterate the text (even MIME encoded) from non-Roman letters to Roman letters, simply select the checkbox.
EOT

$lngmsghint{'msg500070'} = '# Shutdown/Restart';
$lngmsg{'msg500070'} = <<EOT;
Note: It's possible to restart, if SPAMBOX runs as a service or in a script that restarts it after it stops or it runs on WIN32 version Windows 2000(or higher) or it runs on linux,
otherwise this function can only shut SPAMBOX down. In either case, shutdown is possibly not clean -- all SMTP sessions will be interrupted after $MaxFinConWaitTime seconds.<br /><br />
EOT
$lngmsg{'msg500070'} .= <<EOT if $WebIP{$ActWebSess}->{user} eq 'root';
The following command will be started in OS-shell, if SPAMBOX runs not as a service or daemon:<br /><b><font color=green>$AutoRestartCmd</font></b>
EOT

$lngmsghint{'msg500080'} = '# EDIT files window/frame';
$lngmsg{'msg500080'} = <<EOT;
<span class="negative">Attention: This is the real database content!<br />
Incorrect editing hash lists could result in unexpected behavior or dying SPAMBOX!</span><br />
Use |::| as terminator between key and value, for example: 102.1.1.1|::|1234567890 !<br />
If a time is shown human readable, you can change the date or time,<br />
but leave the format as it is ([+]YYYY-MM-DD,hh:mm:ss) and leave a possible \'+\' in front.<br />
Use only one pair of key and value per line.<br />
Comments are not allowed!<br />
While the hash is saved, SPAMBOX is unable to accept new connections!<br />
Be careful saveing large hash here, this could take very long time. Better save the new contents of large hashes and lists to the Importfile, if this option is available. If possible, the DB-Import will be started immediately by the MaintThread!<br />
After saving the contents to the Importfile, you should close this windows and wait until the import has finished!
EOT

$lngmsg{'msg500081'} = 'File should have one entry per line; anything on a line following a number sign ( #) is ignored (a comment). Whitespace at the beginning or end of the line is ignored.';
$lngmsg{'msg500082'} = 'First line specifies text that appears in the subject of report message. The remaining lines are the report message body.';
$lngmsg{'msg500083'} = 'Put here comments to your spambox installation.';
$lngmsg{'msg500084'} = 'For removal of entries from BlackBox (PBBlack) use <a onmousedown="showDisp(\'$ConfigPos{noPB}\')" target="main" href="./#noPB">noPB</a>.
For removal of entries from WhiteBox (PBWhite)  use <a onmousedown="showDisp(\'$ConfigPos{noPBwhite}\')" target="main" href="./#noPBwhite">noPBwhite</a>. For  whitelisting IP\'s use <a onmousedown="showDisp(\'$ConfigPos{whiteListedIPs}\')" target="main" href="./#whiteListedIPs">Whitelisted IP\'s</a> or <a onmousedown="showDisp(\'$ConfigPos{noProcessingIPs}\')" target="main" href="./#noProcessingIPs">No Processing IP\'s</a>. For blacklisting use <a onmousedown="showDisp(\'$ConfigPos{denySMTPConnectionsFrom}\')" target="main" href="./#denySMTPConnectionsFrom">Deny SMTP Connections From these IP\'s</a> and <a onmousedown="showDisp(\'$ConfigPos{denySMTPConnectionsFromAlways}\')" target="main" href="./#denySMTPConnectionsFromAlways">Deny SMTP Connections From these IP\'s Strictly</a>.';

$lngmsg{'msg500086'} = 'CacheEntry: IP/Domain \'11\' CacheIntervalStart 1=fail/2=pass Result/Comment';

$lngmsg{'msg500090'} = 'To take an action, select the action and click "Do It!". To move a file to another location, just copy and delete the file!';
$lngmsg{'msg500091'} = '<br /> For "resend file" action install Email::Send  modules!';

$lngmsg{'msg500092'} = 'IP ranges can be defined as: 182.82.10. ';

$lngmsghint{'msg500093'} = '# the following messages are in one line 0093.$records.0094';
$lngmsg{'msg500093'} = 'This hash/list seems to be too large (';
$lngmsg{'msg500094'} = 'records) to save it from GUI!';

$lngmsg{'msg500095'} = 'Please close this window, and wait until import has finished.';
$lngmsg{'msg500096'} = "This file was trunked to (MaxBytes) $MaxBytes byte. If you resend this file, the resulting view and/or attachments would be destroyed!";

$lngmsghint{'msg500100'} = '# SMTP-Connection - link - hintbox';
$lngmsg{'msg500100'} = 'Click here to open a SMTP-Connections-Window that never stops refreshing. Do not make any changes in the main window, while this SMTP-Connections-Window is still opened! A SMTP-Connections-Window which is started with the default (left beside) link, will stop refreshing if it is not in forground.';

}
