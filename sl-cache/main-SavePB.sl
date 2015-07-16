#line 1 "sub main::SavePB"
package main; sub SavePB {
# save Penalty Box Databases
  if ($pbdb !~ /DB:/o) {
    mlog(0,"saving penalty records") if $MaintenanceLog;
    &SaveHash('PBBlack');
    &SaveHash('PBWhite');
    &SaveHash('PBTrap');
    mlog(0,"saving cache records") if $MaintenanceLog;
    &SaveHash('RBLCache');
    &SaveHash('URIBLCache');
    &SaveHash('SPFCache');
    &SaveHash('PTRCache');
    &SaveHash('MXACache');
    &SaveHash('SBCache');
    &SaveHash('RWLCache');
    &SaveHash('DKIMCache');
    &SaveHash('BATVTag');
    &SaveHash('BackDNS');
    mlog(0,"saving personal Black records") if $MaintenanceLog;
    &SaveHash('PersBlack');
  }
}
