#line 1 "sub main::LDAPQuery"
package main; sub LDAPQuery {
  my ($ldapflt, $ldaproot, $current_email) = @_;
  my $retcode;
  my $retmsg;
  my @ldaplist;
  my $ldaplist;
  my $ldap;
  my $mesg;
  my $entry_count;
  d("LDAPQuery - $ldapflt, $ldaproot, $current_email",1) if $WorkerNumber != 10001;
  $current_email = &batv_remove_tag(0,lc($current_email),'');

  return 1 if &LDAPCacheFind($current_email,'LDAP');
  if (my $nf = $LDAPNotFound{$current_email}) {
      if (time - $nf < 300) {
          mlog(0,"info: found $current_email in LDAPNotFound - skip ldap") if $LDAPLog > 1;
          return 0;
      }
      delete $LDAPNotFound{$current_email};
  }

  d("doing LDAP lookup with $ldapflt in $ldaproot",1) if $WorkerNumber != 10001;

  @ldaplist = split(/\|/o,$LDAPHost);
  $ldaplist = \@ldaplist;

  &sigoffTry(__LINE__);
  my $scheme = 'ldap';
  eval{
  $scheme = 'ldaps' if ($DoLDAPSSL == 1 && $AvailIOSocketSSL);
  $ldap = Net::LDAP->new( $ldaplist,
                          timeout => $LDAPtimeout,
                          scheme => $scheme,
                          inet4 =>  1,
                          inet6 =>  $CanUseIOSocketINET6,
                          getLocalAddress('LDAP',$ldaplist->[0])
                        );
  $ldap->start_tls() if ($DoLDAPSSL == 2 && $AvailIOSocketSSL);
  };
  if(! $ldap) {
    mlog(0,"warning: Couldn't contact LDAP server at $LDAPHost -- check ignored") if $WorkerNumber != 10001;
    &sigonTry(__LINE__);
    $LDAPoffline = 1;
    return !$LDAPFail;
  }
# bind to a directory anonymous or with dn and password
  if ($LDAPLogin) {
    $mesg = $ldap->bind($LDAPLogin, password => $LDAPPassword,  version => $LDAPVersion);
  } else {
    $mesg = $ldap->bind( version => $LDAPVersion );
  }
  $retcode = $mesg->code;
  if ($retcode) {
    mlog(0,"LDAP bind error: $retcode -- check ignored",1) if $WorkerNumber != 10001;
    $ldap->unbind;
    &sigonTry(__LINE__);
    $LDAPoffline = 1;
    return !$LDAPFail;
  }
# perform a search
  $mesg = $ldap->search(base   => $ldaproot,
                        filter => $ldapflt,
                        attrs => ['cn'],
                        sizelimit => 1
                        );
  $retcode = $mesg->code;
  if($retcode > 0 && $retcode != 4) {
    mlog( 0, "LDAP search error: $retcode -- '$ldapflt' check ignored", 1 ) if $WorkerNumber != 10001;
    &sigonTry(__LINE__);
    $ldap->unbind;
    $LDAPoffline = 1;
    return !$LDAPFail;
  }
  $LDAPoffline = 0;
  $entry_count = $mesg->count;
  $retmsg = $mesg->entry(1);
  mlog(0,"info: LDAP Results $ldapflt: $entry_count : $retmsg") if $LDAPLog > 1 && $WorkerNumber != 10001;
  my $fnd = $entry_count ? '' : ' not';
  mlog(0,"info: LDAP - $current_email$fnd found") if $LDAPLog == 1 && $WorkerNumber != 10001;
  d("got $entry_count result(s) from LDAP lookup") if $WorkerNumber != 10001;
  $mesg = $ldap->unbind;  # take down session
  if($entry_count) {
     if($ldaplistdb) {
         $LDAPlist{$current_email}=time;
         mlog(0,"info: LDAP added $current_email to LDAPlist") if $LDAPLog && $WorkerNumber != 10001;
         d("added $current_email to LDAP-cache") if $WorkerNumber != 10001;
     }
     delete $LDAPNotFound{$current_email};
  } else {
     mlog(0,"info: caching result for $current_email in LDAPNotFound") if $LDAPLog > 1;
     $LDAPNotFound{$current_email} = time;
  }
  &sigonTry(__LINE__);
  return $entry_count;
}
