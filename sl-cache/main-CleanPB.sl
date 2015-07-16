#line 1 "sub main::CleanPB"
package main; sub CleanPB {
# clean Penalty Box Databases
  &SavePB if (!$mysqlSlaveMode || $pbdb!~/DB:/o);
  mlog(0,"cleaning penalty records...") if $MaintenanceLog;
  &cleanBlackPB if $DoPenalty && $PBBlackObject;
  &cleanWhitePB if $PBWhiteObject;
  &cleanTrapPB if $PBTrapObject;
}
