#line 1 "sub main::CleanCache"
package main; sub CleanCache {
  mlog(0,"cleaning cache records...") if $MaintenanceLog;
  &cleanCacheRBL() if $RBLCacheExp && $ValidateRBL;
  &cleanCacheURI() if $URIBLCacheInterval && $ValidateURIBL;
  &cleanCacheRWL() if $RWLCacheInterval && $ValidateRWL;
  &cleanCachePTR() if $PTRCacheInterval && $DoReversed;
  &cleanCacheMXA() if $DoDomainCheck && $MXACacheInterval;
  &cleanCacheSPF() if $ValidateSPF && $SPFCacheInterval;
  &cleanCacheDKIM() if $DoDKIM && $DKIMCacheInterval;
  &cleanCacheSB()  if $SBCacheExp;
  &cleanCacheBackDNS() if $BackDNSInterval;
  &cleanCachePersBlack();
}
