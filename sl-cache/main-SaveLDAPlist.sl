#line 1 "sub main::SaveLDAPlist"
package main; sub SaveLDAPlist {
  if ($ldaplistdb !~ /DB:/o) {
    mlog(0,"saving ldaplist") if $MaintenanceLog;
    &SaveHash('LDAPlist');
  }
}
