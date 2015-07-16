#line 1 "sub main::LDAPCacheFind"
package main; sub LDAPCacheFind {
  my ($current_email,$how) = @_;
  d("LDAPCacheFind - $current_email , $how",1) if $WorkerNumber != 10001;
  return 0 unless $ldaplistdb;
  $current_email = lc $current_email;
  if (my ($vt,$vl) = split(/ /o,$LDAPlist{$current_email})) {
    mlog(0,"info: $how - found $current_email in $how-cache (ldaplistdb)") if (${$how.'Log'} && $WorkerNumber != 10001);
    d("$how - found $current_email in $how-cache",1) if $WorkerNumber != 10001;
    if ($vl) {
      $LDAPlist{$current_email}=time." $vl";
    } else {
      $LDAPlist{$current_email}=time;
    }
    return 1;
  }
  d("$how - not found $current_email in $how-cache",1) if $WorkerNumber != 10001;
  mlog(0,"info: $how - $current_email not found in $how-cache (ldaplistdb)") if (${$how.'Log'} >= 2 && $WorkerNumber != 10001);
  return 0;
}
