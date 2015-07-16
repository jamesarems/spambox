#line 1 "sub main::statsTotals"
package main; sub statsTotals {
 my %s = ();
 for (qw(
smtpConnIdleTimeout
smtpConnSSLIdleTimeout
smtpConnTLSIdleTimeout
smtpConnSSL
smtpConnTLS
     ))
 {
     $s{$_}     = $Stats{$_};
     $s{$_.'2'} = $AllStats{$_};
 }

 ($s{smtpConnAcceptedTotal},$s{smtpConnAcceptedTotal2}) = statsCalc([\%Stats,\%AllStats],[qw(
smtpConn
smtpConnNotLogged
)]);

 ($s{smtpConnLimit},$s{smtpConnLimit2}) = statsCalc([\%Stats,\%AllStats],[qw(
AUTHErrors
delayConnection
smtpConnDomainIP
smtpConnLimit
smtpConnLimitFreq
smtpConnLimitIP
smtpSameSubject
)]);

 ($s{smtpConnRejectedTotal},$s{smtpConnRejectedTotal2}) = statsCalc([\%Stats,\%AllStats],[qw(
smtpConnLimit
smtpConnDenied
denyConnectionA
)]);

 ($s{smtpConnTotal}) = statsCalc([\%s],[qw(
smtpConnAcceptedTotal
smtpConnRejectedTotal
)]);

 ($s{smtpConnTotal2}) = statsCalc([\%s],[qw(
smtpConnAcceptedTotal2
smtpConnRejectedTotal2
)]);

 ($s{admConnTotal},$s{admConnTotal2}) = statsCalc([\%Stats,\%AllStats],[qw(
admConn
admConnDenied
)]);

 ($s{statConnTotal},$s{statConnTotal2}) = statsCalc([\%Stats,\%AllStats],[qw(
statConn
statConnDenied
)]);

 ($s{rcptAcceptedLocal},$s{rcptAcceptedLocal2}) = statsCalc([\%Stats,\%AllStats],[qw(
rcptValidated
rcptUnchecked
rcptSpamLover
)]);

 ($s{rcptAcceptedRemote},$s{rcptAcceptedRemote2}) = statsCalc([\%Stats,\%AllStats],[qw(
rcptWhitelisted
rcptNotWhitelisted
)]);

 ($s{rcptUnprocessed},$s{rcptUnprocessed2}) = statsCalc([\%Stats,\%AllStats],[qw(
rcptUnprocessed
)]);

 ($s{rcptReport},$s{rcptReport2}) = statsCalc([\%Stats,\%AllStats],[qw(
rcptReportHam
rcptReportSpam
rcptReportRedlistAdd
rcptReportRedlistRemove
rcptReportWhitelistAdd
rcptReportWhitelistRemove
)]);

 ($s{rcptAcceptedTotal}) = statsCalc([\%s],[qw(
rcptAcceptedLocal
rcptAcceptedRemote
rcptReport
rcptUnprocessed
)]);
 ($s{rcptAcceptedTotal2}) = statsCalc([\%s],[qw(
rcptAcceptedLocal2
rcptAcceptedRemote2
rcptReport2
rcptUnprocessed2
)]);


 ($s{rcptRejectedLocal},$s{rcptRejectedLocal2}) = statsCalc([\%Stats,\%AllStats],[qw(
rcptDelayed
rcptDelayedLate
rcptDelayedExpired
rcptEmbargoed
rcptNonexistent
rcptSpamBucket
)]);


 ($s{rcptRejectedRemote},$s{rcptRejectedRemote2}) = statsCalc([\%Stats,\%AllStats],[qw(
rcptRelayRejected
)]);

($s{rcptRejectedTotal}) = statsCalc([\%s],[qw(
rcptRejectedLocal
rcptRejectedRemote
)]);
($s{rcptRejectedTotal2}) = statsCalc([\%s],[qw(
rcptRejectedLocal2
rcptRejectedRemote2
)]);

($s{rcptTotal}) = statsCalc([\%s],[qw(
rcptAcceptedTotal
rcptRejectedTotal
)]);
($s{rcptTotal2}) = statsCalc([\%s],[qw(
rcptAcceptedTotal2
rcptRejectedTotal2
)]);

 ($s{msgAcceptedTotal},$s{msgAcceptedTotal2}) = statsCalc([\%Stats,\%AllStats],[qw(
bhams
locals
noprocessing
spamlover
whites
)]);

 ($s{msgRejectedTotal},$s{msgRejectedTotal2}) = statsCalc([\%Stats,\%AllStats],[qw(
AUTHErrors
DCC
Razor
batvErrors
blacklisted
bombSender
bombBlack
bombs
bspams
crashAnalyze
denyConnection
denyConnectionA
dkim
dkimpre
forgedHelo
helolisted
internaladdresses
invalidHelo
localFrequency
msgBackscatterErrors
msgDelayed
msgMaxErrors
msgMaxVRFYErrors
msgMSGIDtrErrors
msgNoRcpt
msgNoSRSBounce
msgscoring
msgverify
mxaMissing
pbdenied
pbextreme
penaltytrap
preHeader
ptrMissing
ptrInvalid
rblfails
sbblocked
scripts
senderInvalidLocals
smtpConnDenied
smtpConnDomainIP
smtpConnLimitFreq
smtpSameSubject
spambucket
spffails
uriblfails
viri
viridetected
)]);

($s{msgTotal}) = statsCalc([\%s],[qw(
msgAcceptedTotal
msgRejectedTotal
)]);
($s{msgTotal2}) = statsCalc([\%s],[qw(
msgAcceptedTotal2
msgRejectedTotal2
)]);

 return %s;
}
