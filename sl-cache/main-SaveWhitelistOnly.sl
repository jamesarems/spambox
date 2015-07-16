#line 1 "sub main::SaveWhitelistOnly"
package main; sub SaveWhitelistOnly {
 d('SaveWhitelistOnly');
 if ($UpdateWhitelist && $whitelistdb !~ /DB:/o) {
    mlog(0,"saving whitelist") if $MaintenanceLog;
    &SaveHash('Whitelist');
  }
  if ($UpdateWhitelist && $redlistdb !~ /DB:/o) {
    mlog(0,"saving redlist") if $MaintenanceLog;
    &SaveHash('Redlist');
  }
}
