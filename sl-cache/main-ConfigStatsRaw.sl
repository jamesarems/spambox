#line 1 "sub main::ConfigStatsRaw"
package main; sub ConfigStatsRaw {

 # must pass by ref
 my ( $href, $qsref ) = @_;
 my $head; $head = $$href if $href;
 my $qs;     $qs = $$qsref if $qsref;

 my %tots = ();
 {
 lock(%Stats) if (is_shared(%Stats));
 SaveStats();
 %tots=statsTotals();
 }
 my $upt=(time-$Stats{starttime})/(24*3600);
 my $upt2=(time-$AllStats{starttime})/(24*3600);
 my $uptime=sprintf("%.3f",$upt);
 my $uptime2=sprintf("%.3f",$upt2);
 my $mpd=sprintf("%.1f",$upt==0 ? 0 : $tots{msgTotal}/$upt);
 my $mpd2=sprintf("%.1f",$upt2==0 ? 0 : $tots{msgTotal2}/$upt2);
 my $pct=sprintf("%.1f",$tots{msgTotal}-$Stats{locals}==0 ? 0 : 100*$tots{msgRejectedTotal}/($tots{msgTotal}-$Stats{locals}));
 my $pct2=sprintf("%.1f",$tots{msgTotal2}-$AllStats{locals}==0 ? 0 : 100*$tots{msgRejectedTotal2}/($tots{msgTotal2}-$AllStats{locals}));
 my $cpuAvg=sprintf("%.2f\%",(! $Stats{cpuTime} ? 0 : 100*$Stats{cpuBusyTime}/$Stats{cpuTime}));
 my $cpuAvg2=sprintf("%.2f\%",(! $AllStats{cpuTime} ? 0 : 100*$AllStats{cpuBusyTime}/$AllStats{cpuTime}));
 my $currStat = &StatusASSP();
 $currStat = ($currStat =~ /not healthy/io) ? 'not healthy' : 'healthy' ;
 my $memory = memoryUsage().'MB';

 my $sr = "\n";
 foreach (keys %ScoreStats) {
     $sr .= "Scored$_ | $ScoreStats{$_} | $AllScoreStats{$_}\n";
 }
<<EOT . $sr;
$headerHTTP
ASSP Proxy Uptime | $uptime days | $uptime2 days
Messages Processed | $tots{msgTotal} ($mpd per day) | $tots{msgTotal2} ($mpd2 per day)
Non-Local Mail Blocked | $pct% | $pct2%
CPU Usage | $cpuAvg | $cpuAvg2
Current memory usage | $memory
Concurrent SMTP Sessions | $smtpConcurrentSessions ($Stats{smtpMaxConcurrentSessions} max) | $AllStats{smtpMaxConcurrentSessions} max
Current healthy status | $currStat

SMTP Connections Received | $tots{smtpConnTotal} | $tots{smtpConnTotal2}
SMTP Connections Accepted | $tots{smtpConnAcceptedTotal} | $tots{smtpConnAcceptedTotal2}
SMTP Connections Rejected | $tots{smtpConnRejectedTotal} | $tots{smtpConnRejectedTotal2}
Envelope Recipients Processed | $tots{rcptTotal} | $tots{rcptTotal2}
Envelope Recipients Accepted | $tots{rcptAcceptedTotal} | $tots{rcptAcceptedTotal2}
Envelope Recipients Rejected | $tots{rcptRejectedTotal} | $tots{rcptRejectedTotal2}
Messages Processed | $tots{msgTotal} | $tots{msgTotal2}
Messages Passed | $tots{msgAcceptedTotal} | $tots{msgAcceptedTotal2}
Messages Rejected | $tots{msgRejectedTotal} | $tots{msgRejectedTotal2}
Admin Connections Received | $tots{admConnTotal} | $tots{admConnTotal2}
Admin Connections Accepted | $Stats{admConn} | $AllStats{admConn}
Admin Connections Rejected | $Stats{admConnDenied} | $AllStats{admConnDenied}
Stat Connections Received | $tots{statConnTotal} | $tots{statConnTotal2}
Stat Connections Accepted | $Stats{statConn} | $AllStats{statConn}
Stat Connections Rejected | $Stats{statConnDenied} | $AllStats{statConnDenied}

Accepted Logged SMTP Connections | $Stats{smtpConn} | $AllStats{smtpConn}
SSL SMTP Connections | $Stats{smtpConnSSL} | $AllStats{smtpConnSSL}
TLS SMTP Connections | $Stats{smtpConnTLS} | $AllStats{smtpConnTLS}
Not Logged SMTP Connections | $Stats{smtpConnNotLogged} | $AllStats{smtpConnNotLogged}
SMTP Connection Limits | $tots{smtpConnLimit} | $tots{smtpConnLimit2}
Overall Limits | $Stats{smtpConnLimit} | $AllStats{smtpConnLimit}
By IP Limits | $Stats{smtpConnLimitIP} | $AllStats{smtpConnLimitIP}
By Delay on PB | $Stats{delayConnection} | $AllStats{delayConnection}
BY IP By AUTH Errors Count | $Stats{AUTHErrors} | $AllStats{AUTHErrors}
By IP Frequency Limits | $Stats{smtpConnLimitFreq} | $AllStats{smtpConnLimitFreq}
By Domain IP Limits | $Stats{smtpConnDomainIP} | $AllStats{smtpConnDomainIP}
By Same Subjects Limits | $Stats{smtpSameSubject} | $AllStats{smtpSameSubject}
SMTP Connections Timeout | $tots{smtpConnIdleTimeout} | $tots{smtpConnIdleTimeout2}
SMTP SSL-Connections Timeout | $tots{smtpConnSSLIdleTimeout} | $tots{smtpConnSSLIdleTimeout2}
SMTP TLS-Connections Timeout | $tots{smtpConnTLSIdleTimeout} | $tots{smtpConnTLSIdleTimeout2}
Denied SMTP Connections | $Stats{smtpConnDenied} | $AllStats{smtpConnDenied}
SMTP damping | $Stats{damping} | $AllStats{damping}

Local Recipients Accepted | $tots{rcptAcceptedLocal} | $tots{rcptAcceptedLocal2}
Validated Recipients | $Stats{rcptValidated} | $AllStats{rcptValidated}
Unchecked Recipients | $Stats{rcptUnchecked} | $AllStats{rcptUnchecked}
Spam-Lover Recipients | $Stats{rcptSpamLover} | $AllStats{rcptSpamLover}
Remote Recipients Accepted | $tots{rcptAcceptedRemote} | $tots{rcptAcceptedRemote2}
Whitelisted Recipients | $Stats{rcptWhitelisted} | $AllStats{rcptWhitelisted}
Not Whitelisted Recipients | $Stats{rcptNotWhitelisted} | $AllStats{rcptNotWhitelisted}
Noprocessed Recipients | $Stats{rcptUnprocessed} | $AllStats{rcptUnprocessed}
Email Reports | $tots{rcptReport} | $tots{rcptReport2}
Spam Reports | $Stats{rcptReportSpam} | $AllStats{rcptReportSpam}
Ham Reports | $Stats{rcptReportHam} | $AllStats{rcptReportHam}
Whitelist Additions | $Stats{rcptReportWhitelistAdd} | $AllStats{rcptReportWhitelistAdd}
Whitelist Deletions | $Stats{rcptReportWhitelistRemove} | $AllStats{rcptReportWhitelistRemove}
Redlist Additions | $Stats{rcptReportRedlistAdd} | $AllStats{rcptReportRedlistAdd}
Redlist Deletions | $Stats{rcptReportRedlistRemove} | $AllStats{rcptReportRedlistRemove}
Local Recipients Rejected | $tots{rcptRejectedLocal} | $tots{rcptRejectedLocal2}
Nonexistent Recipients | $Stats{rcptNonexistent} | $AllStats{rcptNonexistent}
Delayed Recipients | $Stats{rcptDelayed} | $AllStats{rcptDelayed}
Delayed (Late) Recipients | $Stats{rcptDelayedLate} | $AllStats{rcptDelayedLate}
Delayed (Expired) Recipients | $Stats{rcptDelayedExpired} | $AllStats{rcptDelayedExpired}
Embargoed Recipients | $Stats{rcptEmbargoed} | $AllStats{rcptEmbargoed}
Spam Bucketed Recipients | $Stats{rcptSpamBucket} | $AllStats{rcptSpamBucket}
Remote Recipients Rejected | $tots{rcptRejectedRemote} | $tots{rcptRejectedRemote2}
Relay Attempts Rejected | $Stats{rcptRelayRejected} | $AllStats{rcptRelayRejected}

Bayesian Hams | $Stats{bhams} | $AllStats{bhams}
Whitelisted | $Stats{whites} | $AllStats{whites}
Local | $Stats{locals} | $AllStats{locals}
Noprocessing | $Stats{noprocessing} | $AllStats{noprocessing}
Spamlover Spams Passed | $Stats{spamlover} | $AllStats{spamlover}
Bayesian Spams | $Stats{bspams} | $AllStats{bspams}
Domains Blacklisted | $Stats{blacklisted} | $AllStats{blacklisted}
HELO Blacklisted | $Stats{helolisted} | $AllStats{helolisted}
HELO Invalid | $Stats{invalidHelo} | $AllStats{invalidHelo}
HELO Forged | $Stats{forgedHelo} | $AllStats{forgedHelo}
Missing MX | $Stats{mxaMissing} | $AllStats{mxaMissing}
Missing PTR | $Stats{ptrMissing} | $AllStats{ptrMissing}
Invalid PTR | $Stats{ptrInvalid} | $AllStats{ptrInvalid}
Spam Collected Messages | $Stats{spambucket} | $AllStats{spambucket}
Penalty Trap Messages | $Stats{penaltytrap} | $AllStats{penaltytrap}
Bad Attachments | $Stats{viri} | $AllStats{viri}
Viruses Detected | $Stats{viridetected} | $AllStats{viridetected}
Sender Regex | $Stats{bombSender} | $AllStats{bombSender}
Bomb Regex | $Stats{bombs} | $AllStats{bombs}
Penalty Box | $Stats{pbdenied} | $AllStats{pbdenied}
Message Scoring | $Stats{msgscoring} | $AllStats{msgscoring}
Invalid Local Sender | $Stats{senderInvalidLocals} | $AllStats{senderInvalidLocals}
Invalid Internal Mail | $Stats{internaladdresses} | $AllStats{internaladdresses}
Scripts | $Stats{scripts} | $AllStats{scripts}
SPF Failures | $Stats{spffails} | $AllStats{spffails}
RBL Failures | $Stats{rblfails} | $AllStats{rblfails}
URIBL Failures | $Stats{uriblfails} | $AllStats{uriblfails}
Max Errors Exceeded | $Stats{msgMaxErrors} | $AllStats{msgMaxErrors}
Delayed | $Stats{msgDelayed} | $AllStats{msgDelayed}
Empty Recipient | $Stats{msgNoRcpt} | $AllStats{msgNoRcpt}
Not SRS Signed Bounces | $Stats{msgNoSRSBounce} | $AllStats{msgNoSRSBounce}
MSGID Signature | $Stats{msgMSGIDtrErrors} | $AllStats{msgMSGIDtrErrors}
DKIM | $Stats{dkim} | $AllStats{dkim}
DKIM pre Check | $Stats{dkimpre} | $AllStats{dkimpre}
Pre Header | $Stats{preHeader} | $AllStats{preHeader}

EOT
}
