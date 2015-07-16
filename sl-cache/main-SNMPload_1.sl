#line 1 "sub main::SNMPload_1"
package main; sub SNMPload_1 {
    $subOID{'.1.0.0'} = [\&SNMPload_1_0,[\&SNMPload_1_0_healthy], 1, 0];
    $subOID{'.1.1.0'} = [\&SNMPload_1_0,[\&SNMPload_1_0_healthy], \$webStatHealthyResp, \$webStatNotHealthyResp];
    $subOID{'.1.2.0'} = [\&SNMPload_1_0,\$doShutdownForce, 0, 1];
    $subOID{'.1.3.0'} = [\&SNMPload_1_0,\$doShutdownForce, 'shutdown in progress', 'running'];
    $subOID{'.1.4.0'} = $MAINVERSION;
    $subOID{'.1.5.0'} = $spambox;
    $subOID{'.1.6.0'} = $];
    $subOID{'.1.7.0'} = $perl;
    $subOID{'.1.8.0'} = $^O;
    $subOID{'.1.9.0'} = \$localhostname;
    $subOID{'.1.10.0'} = \$localhostip;
    $subOID{'.1.11.0'} = \$myName;
    $subOID{'.1.12.0'} = \$NewAsspURL;
    $subOID{'.1.13.0'} = [\&SNMPload_1_13];
    $subOID{'.1.14.0'} = [\&SNMPload_1_14];

    $subOID{'.1.20.1.0'} = [\&timestring,\$nextBDBsync,'',''];
    $subOID{'.1.20.2.0'} = [\&timestring,\$NextConfigReload,'',''];
    $subOID{'.1.20.3.0'} = [\&timestring,\$nextCleanBATVTag,'',''];
    $subOID{'.1.20.4.0'} = [\&timestring,\$nextCleanCache,'',''];
    $subOID{'.1.20.5.0'} = [\&timestring,\$nextCleanIPDom,'',''];
    $subOID{'.1.20.6.0'} = [\&timestring,\$nextCleanDelayDB,'',''];
    $subOID{'.1.20.7.0'} = [\&timestring,\$nextCleanPB,'',''];
    $subOID{'.1.20.8.0'} = [\&timestring,\$nextDBBackup,'',''];
    $subOID{'.1.20.9.0'} = [\&timestring,\$nextDBcheck,'',''];
    $subOID{'.1.20.10.0'} = [\&timestring,\$nextDNSCheck,'',''];
    $subOID{'.1.20.11.0'} = [\&timestring,\$nextdetectHourJob,'',''];
    $subOID{'.1.20.12.0'} = [\&timestring,\$nextExport,'',''];
    $subOID{'.1.20.13.0'} = [\&timestring,\$nextGlobalUploadBlack,'',''];
    $subOID{'.1.20.14.0'} = [\&timestring,\$nextGlobalUploadWhite,'',''];
    $subOID{'.1.20.15.0'} = [\&timestring,\$nextHashFileCheck,'',''];
    $subOID{'.1.20.16.0'} = [\&timestring,\$nextLDAPcrossCheck,'',''];
    $subOID{'.1.20.17.0'} = [\&timestring,\$nextRebuildSpamDB,'',''];
    $subOID{'.1.20.18.0'} = [\&timestring,\$nextResendMail,'',''];
    $subOID{'.1.20.19.0'} = [\&timestring,\$NextSPAMBOXFileDownload,'',''];
    $subOID{'.1.20.20.0'} = [\&timestring,\$NextVersionFileDownload,'',''];
    $subOID{'.1.20.21.0'} = [\&timestring,\$NextBackDNSFileDownload,'',''];
    $subOID{'.1.20.22.0'} = [\&timestring,\$NextCodeChangeCheck,'',''];
    $subOID{'.1.20.23.0'} = [\&timestring,\$NextDroplistDownload,'',''];
    $subOID{'.1.20.24.0'} = [\&timestring,\$NextGriplistDownload,'',''];
    $subOID{'.1.20.25.0'} = [\&timestring,\$NextPOP3Collect,'',''];
    $subOID{'.1.20.26.0'} = [\&timestring,\$NextSaveStats,'',''];
    $subOID{'.1.20.27.0'} = [\&timestring,\$NextTLDlistDownload,'',''];
    $subOID{'.1.20.28.0'} = [\&timestring,\$NextSyncConfig,'',''];
    $subOID{'.1.20.29.0'} = [\&timestring,\$NextGroupsReload,'',''];
    $subOID{'.1.20.30.0'} = [\&timestring,\$nextBlockReportSchedule,'',''];
    $subOID{'.1.20.31.0'} = [\&timestring,\$$nextFileAgeSchedule,'',''];
    $subOID{'.1.20.32.0'} = [\&timestring,\$nextQueueSchedule,'',''];
    $subOID{'.1.20.33.0'} = [\&timestring,\$nextMemoryUsageCheckSchedule,'',''];

    mlog(0,"info: SNMP read application OIDs .1.0 - .1.36") if $SNMPLog == 3;
    &SNMPload_1_30();
    &SNMPload_1_31();
    &SNMPload_1_32();
    $subOIDLastLoad{1} = 9999999999;
}
