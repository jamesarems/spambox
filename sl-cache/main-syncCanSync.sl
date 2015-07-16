#line 1 "sub main::syncCanSync"
package main; sub syncCanSync {
    return ($syncConfigFile && $syncCFGPass && $syncServer && ($enableCFGShare or $isShareMaster or $isShareSlave)) ? 1 : 0;
}
