#line 1 "sub main::LDAPList"
package main; sub LDAPList {
  my %ATTR = @_;
  $ATTR{attr} ||= 'uid';
  my $retcode;
  my @retmsg;
  my @ldaplist;
  my $ldaplist;
  my $ldap;
  my $mesg;

  if ($ATTR{host}) {
      $ATTR{scheme} ||= 'ldap';
      $ATTR{scheme} = 'ldap' unless $AvailIOSocketSSL;
      delete $ATTR{starttls} if $ATTR{scheme} eq 'ldaps';
  } else {
      $ATTR{host} = $LDAPHost;
      $ATTR{scheme} = ($DoLDAPSSL == 1 && $AvailIOSocketSSL) ? 'ldaps' : 'ldap';
      $ATTR{starttls} = ($DoLDAPSSL == 2 && $AvailIOSocketSSL);
      delete $ATTR{starttls} if $ATTR{scheme} eq 'ldaps';
      $ATTR{version} = $LDAPVersion;
      $ATTR{user} = $LDAPLogin if $LDAPLogin;
      $ATTR{password} = $LDAPPassword if $LDAPPassword;
      $ATTR{timeout} = $LDAPtimeout;
      $ATTR{base} ||= $LDAPRoot if $LDAPRoot;
  }
  @ldaplist = split(/\|/o,$ATTR{host});
  $ldaplist = \@ldaplist;

  if ($LDAPLog > 2) {
      my $parms;
      foreach (sort keys %ATTR) {
          $parms .= "$_ => $ATTR{$_}\n";
      }
      mlog(0,"info: LDAPList request uses the following parameters:\n$parms");
  }

  eval{
  $ldap = Net::LDAP->new($ldaplist,
                         timeout => $ATTR{timeout},
                         scheme => $ATTR{scheme},
                         inet4 =>  1,
                         inet6 =>  $CanUseIOSocketINET6,
                         getLocalAddress('LDAP',$ldaplist->[0])
                        );
  $ldap->start_tls() if $ATTR{starttls};
  };
  if(! $ldap || $@) {
    mlog(0,"warning: Couldn't contact LDAP server at $LDAPHost - $@");
    return;
  }
# bind to a directory anonymous or with dn and password
  eval{
  if ($ATTR{user}) {
    $mesg = $ldap->bind($ATTR{user}, password => $ATTR{password},  version => $ATTR{version});
  } else {
    $mesg = $ldap->bind( version => $ATTR{version} );
  }
  $retcode = $mesg->code;
  };
  if ($retcode or $@) {
    my $wtext;
    $wtext = $retcode ? $mesg->error : $ldap->error;
    my $warn = "warning: got return code $retcode ".($wtext?"(error: $wtext) ": ' ')."from LDAP server on bind";
    $warn .= " - $@" if $@;
    mlog(0,$warn);
    eval{$ldap->unbind};
    return;
  }
# perform a search
  eval{
  $mesg = $ldap->search(base => $ATTR{base},
                        filter => $ATTR{ldapfilt},
                        attrs => [$ATTR{attr}]
                        );
  $retcode = $mesg->code;
  };
  if(($retcode > 0 && $retcode != 4) or $@) {
    my $wtext;
    $wtext = $retcode ? $mesg->error : $ldap->error;
    my $warn = "warning: got return code $retcode ".($wtext?"(error: $wtext) ": ' ')."from LDAP server on search";
    $warn .= " - $@" if $@;
    mlog(0,$warn);
    eval{$ldap->unbind};
    return;
  }

  eval{
  foreach my $entry ($mesg->entries) {
    my $val = $entry->get_value($ATTR{attr}, 'asref' => 1);
    if ($val) {
        mlog(0,"info: got LDAP entry - @{$val}") if $LDAPLog > 1;
        push @retmsg, @{$val};
    } else {
        mlog(0,"info: got empty LDAP entry") if $LDAPLog > 2;
    }
  }
  my $max = scalar @retmsg;
  mlog(0,"info: got $max entries from LDAP server on search '$ATTR{ldapfilt}' and attribute '$ATTR{attr}'") if $LDAPLog > 1;
  };
  mlog(0,"error: unable to read attributes from LDAP server - $@") if $@;
  eval{$mesg = $ldap->unbind;};  # take down session
  return @retmsg;
}
