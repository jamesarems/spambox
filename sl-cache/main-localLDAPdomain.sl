#line 1 "sub main::localLDAPdomain"
package main; sub localLDAPdomain {
  my $h = shift;
  d("localLDAPdomain - $h",1);
  $h =~ tr/A-Z/a-z/;
  return 1 if &LDAPCacheFind('@'.$h,'LDAP');
  return 0 unless $CanUseLDAP;
  return 0 unless $ldLDAP;
  my $ldapflt = $ldLDAPFilter;
  $ldapflt =~ s/DOMAIN/$h/go;
  my $ldaproot = $ldLDAPRoot || $LDAPRoot;
  $ldaproot =~ s/DOMAIN/$h/go;
  return LDAPQuery($ldapflt, $ldaproot,$h);
}
