#line 1 "sub main::localmailaddress"
package main; sub localmailaddress {
  my ($fh,$current_email) = @_;
  d("localmailaddress - $current_email",1) if $WorkerNumber != 10001;
  $current_email = &batv_remove_tag(0,$current_email,'');
  $current_email =~ tr/A-Z/a-z/;
  my $at_position = index($current_email, '@');
  my $current_username = substr($current_email, 0, $at_position);
  my $current_domain = substr($current_email, $at_position + 1);
  my $ldapflt = $LDAPFilter;
  $ldapflt =~ s/EMAILADDRESS/$current_email/go;

  $ldapflt =~ s/USERNAME/$current_username/go;
  $ldapflt =~ s/DOMAIN/$current_domain/go;
  my $ldaproot = $LDAPRoot;
  $ldaproot =~ s/DOMAIN/$current_domain/go;
  if ( matchSL( $current_email, 'LocalAddresses_Flat' ) ) {
      $LDAPlist{'@'.$current_domain} = time if $ldaplistdb;
      return 1;
  }
  if (&LDAPCacheFind($current_email,'LDAP')) {
      $LDAPlist{'@'.$current_domain} = time if $ldaplistdb && $ldLDAPFilter;
      return 1;
  }
  if($DoLDAP && $CanUseLDAP && LDAPQuery($ldapflt, $ldaproot,$current_email)) {
      $LDAPlist{'@'.$current_domain} = time if (!$LDAPoffline && $ldaplistdb && $ldLDAPFilter);
      return 1;
  }
  if($DoVRFY && (&matchHashKey('FlatVRFYMTA',"\@$current_domain") or &matchHashKey('DomainVRFYMTA',$current_domain))
             && $CanUseNetSMTP
             && $current_email =~ /[^@]+\@[^@]+/o
             && localvrfy2MTA($fh,$current_email))
  {
      $LDAPlist{'@'.$current_domain} = time if (! ($fh && $Con{$fh}->{userTempFail}) && $ldaplistdb);
      return 1;
  }
  return 0;
}
