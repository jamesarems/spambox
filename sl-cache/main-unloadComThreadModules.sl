#line 1 "sub main::unloadComThreadModules"
package main; sub unloadComThreadModules {
    unloadNameSpace 'Win32::Daemon';
    unloadNameSpace 'Win32::API::OutputDebugString';
    unloadNameSpace 'Win32::OLE';
    unloadNameSpace 'Sys::Syslog';
    unloadNameSpace 'File::ReadBackwards';
    unloadNameSpace 'Thread::State';
    unloadNameSpace 'Compress::Zlib';
    unloadNameSpace 'LWP::Simple';
    unloadNameSpace 'HTTP::Request::Common';
    unloadNameSpace 'LWP::UserAgent';
    unloadNameSpace 'Sys::MemInfo';
    unloadNameSpace 'NetSNMP::agent';
    unloadNameSpace 'NetSNMP::ASN';
    unloadNameSpace 'NetSNMP::default_store';
    unloadNameSpace 'NetSNMP::agent::default_store';
    unloadNameSpace 'Schedule::Cron';
    unloadNameSpace 'Tie::RDBM' unless $useTieRDBM;
    %lngmsg =();
    undef %lngmsg;
    %lngmsghint =();
    undef %lngmsghint;

    undef $GPBinstallLib;
    undef $GPBCompLibVer;

    undef $kudos;
    undef $footers;
    undef $headers;
    undef $headerTOC;
    undef $headerGlosar;
    %glosarIndex = ();
    undef $headerDTDStrict;
    undef $headerDTDTransitional;
    undef $headerHTTP;

    unloadSub 'BlockReportFromQ';
    unloadSub 'BlockReportText';
    unloadSub 'BlockReportGetCSS';
    unloadSub 'BlockReportGetImage';
    unloadSub 'BlockReportHTMLTextWrap';
    unloadSub 'calcWorkers';
    unloadSub 'canUserDo';
    unloadSub 'ChangeMyPassword';
    unloadSub 'CheckTableStructure';
    unloadSub 'cleanBlackPB';
    unloadSub 'CleanCache';
    unloadSub 'cleanCacheBackDNS';
    unloadSub 'cleanCacheBackDNS2';
    unloadSub 'cleanCacheBATVTag';
    unloadSub 'cleanCacheIPNumTries';
    unloadSub 'cleanCacheLocalFrequency';
    unloadSub 'cleanCacheMXA';
    unloadSub 'cleanCachePersBlack';
    unloadSub 'cleanCachePTR';
    unloadSub 'cleanCacheRBL';
    unloadSub 'cleanCacheRWL';
    unloadSub 'cleanCacheSB';
    unloadSub 'cleanCacheSMTPdomainIP';
    unloadSub 'cleanCacheSPF';
    unloadSub 'cleanCacheSSLfailed';
    unloadSub 'cleanCacheURI';
    unloadSub 'CleanDelayDB';
    unloadSub 'CleanPB';
    unloadSub 'cleanTrapPB';
    unloadSub 'cleanUpCollection';
    unloadSub 'cleanUpFiles';
    unloadSub 'cleanUpMaillog';
    unloadSub 'cleanUpMaxFiles';
    unloadSub 'cleanWhitePB';
    unloadSub 'CleanWhitelist';
    unloadSub 'ConfigEdit';
    unloadSub 'ConfigLists';
    unloadSub 'ConfigMaillog';
    unloadSub 'ConfigQuit';
    unloadSub 'ConfigStats';
    unloadSub 'ConfigStatsRaw';
    unloadSub 'ConfigStatsXml';
    unloadSub 'ConToThread';
    unloadSub 'debugWrite';
    unloadSub 'GitHUB';
    unloadSub 'downSPAMBOX';
    unloadSub 'downloadSPAMBOXVersion';
    unloadSub 'downloadBackDNS';
    unloadSub 'downloadDropList';
    unloadSub 'downloadGrip';
    unloadSub 'downloadHTTP';
    unloadSub 'downloadTLDList';
    unloadSub 'downloadVersionFile';
    unloadSub 'exportDB';
    unloadSub 'exportExtreme';
    unloadSub 'exportMysqlDB';
    unloadSub 'fixConfigSettings';
    unloadSub 'BlockReportGen';
    unloadSub 'genCerts';
    unloadSub 'genGlobalPBBlack';
    unloadSub 'genGlobalPBWhite';
    unloadSub 'getBestWorker';
    unloadSub 'BlockReasonsGet';
    unloadSub 'getStuckWorker';
    unloadSub 'importDB';
    unloadSub 'importMysqlDB';
    unloadSub 'init';
    unloadSub 'installService';
    unloadSub 'LDAPcrossCheck';
    unloadSub 'loadPluginConfig';
    unloadSub 'MainLoop';
    unloadSub 'MainLoop2';
    unloadSub 'ManageAdminUsers';
    unloadSub 'memoryUsage';
    unloadSub 'mergeBackDNS';
    unloadSub 'newListen';
    unloadSub 'newListenSSL';
    unloadSub 'newThread';
    unloadSub 'NewStatConnection';
    unloadSub 'NewWebConnection';
    unloadSub 'niceConfig';
    unloadSub 'niceLink';
    unloadSub 'niceConfigPos';
    unloadSub 'POP3Collect';
    unloadSub 'putAdminUsers';
    unloadSub 'registerGlobalClient';
    unloadSub 'reloadConfigFile';
    unloadSub 'RemovePid';
    unloadSub 'removePluginConfig';
    unloadSub 'renderConfigHTML';
    unloadSub 'resend_mail';
    unloadSub 'BlockedMailResend';
    unloadSub 'resendError';
    unloadSub 'resetFH';
    unloadSub 'ResetStats';
    unloadSub 'return_cfg';
    unloadSub 'runRebuild';
    unloadSub 'SaveConfig';
    unloadSub 'SaveConfigSettings';
    unloadSub 'SaveDelaydb';
    unloadSub 'SaveHash';
    unloadSub 'SaveLDAPlist';
    unloadSub 'SavePB';
    unloadSub 'SaveStats';
    unloadSub 'SaveWhitelist';
    unloadSub 'SaveWhitelistOnly';
    unloadSub 'sendGlobalFile';
    unloadSub 'serviceCheck';
    unloadSub 'setMainLang';
    unloadSub 'Shutdown';
    unloadSub 'ShutdownFrame';
    unloadSub 'ShutdownList';
    unloadSub 'SMTPSessionLimitCheck';
    unloadSub 'SNMPcleanHTML';
    unloadSub 'SNMPderefVal';
    unloadSub 'SNMPgetUsers';
    unloadSub 'SNMPhandler';
    unloadSub 'SNMPload_1';
    unloadSub 'SNMPload_1_0';
    unloadSub 'SNMPload_1_0_healthy';
    unloadSub 'SNMPload_1_13';
    unloadSub 'SNMPload_1_30';
    unloadSub 'SNMPload_1_31';
    unloadSub 'SNMPload_2';
    unloadSub 'SNMPload_2_X56';
    unloadSub 'SNMPload_2_X56s';
    unloadSub 'SNMPload_3';
    unloadSub 'SNMPload_4';
    unloadSub 'SNMPload_5';
    unloadSub 'SNMPStats';
    unloadSub 'SNMPVarType';
    unloadSub 'StatsGetModules';
    unloadSub 'StatLine';
    unloadSub 'statRequest';
    unloadSub 'StatTraffic';
    unloadSub 'stopSMTPThreads';
    unloadSub 'switchUsers';
    unloadSub 'tellThreadQuit';
    unloadSub 'tellThreadsReReadConfig';
    unloadSub 'ThreadMaintMain';
    unloadSub 'ThreadMaintStart';
    unloadSub 'ThreadRebuildSpamDBMain';
    unloadSub 'ThreadRebuildSpamDBStart';
    unloadSub 'ThreadsWakeUp';
    unloadSub 'tosyslog';
    unloadSub 'w32dbg';
    unloadSub 'WaitForAllThreads';
    unloadSub 'WebAuth';
    unloadSub 'webBlock';
    unloadSub 'webConfig';
    unloadSub 'WebDone';
    unloadSub 'WebLogout';
    unloadSub 'WebPermission';
    unloadSub 'webRequest';
    unloadSub 'WebTraffic';
    unloadSub 'write_rebuild_module';

# unneeded config subs

    unloadSub 'ConfigChangeStatPort';
    unloadSub 'ConfigChangePassword';
    unloadSub 'ConfigChangePassPhrase';
    unloadSub 'ConfigChangeLogfile';
    unloadSub 'configChangeWorkerPriority';
    unloadSub 'configChangeNumThreads';
    unloadSub 'configChangeAutoReloadCfg';
    unloadSub 'configUpdateGlobalClient';
    unloadSub 'configUpdateGlobalHidden';
    unloadSub 'configChangeRSRBSched';
    unloadSub 'configChangeSched';
    unloadSub 'configChangeSNMP';
}
