#line 1 "sub main::LDAPcrossCheck"
package main; sub LDAPcrossCheck {
  my $k;
  my $v;
  my $current_email;
  my $at_position;
  my $current_username;
  my $current_domain;
  my $ldapflt;
  my $ldaproot;
  my $retcode;
  my $retmsg;
  my @ldaplist;
  my $ldaplist;
  my $ldap;
  my $mesg;
  my $entry_count;
  my $t;
  my $timeout = $VRFYQueryTimeOut ? $VRFYQueryTimeOut : 5;
  my $forceRCPTTO;

  if(! $ldaplistdb) {
      mlog(0,"warning: unable to do crosscheck - ldaplistdb is not configured");
      return;
  }

  $t = time;
  
  mlog(0,"LDAP/VRFY-crosscheck started") if $MaintenanceLog;
  d("doing LDAP/VRFY-crosscheck");

  @ldaplist = split(/\|/o,$LDAPHost);
  $ldaplist = \@ldaplist;

  if ($CanUseLDAP && $DoLDAP && @ldaplist) {
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
        mlog(0,"Couldn't contact LDAP server at $LDAPHost -- no LDAP-crosscheck is done") if $MaintenanceLog;
      } else {
          if ($LDAPLogin) {
            $mesg = $ldap->bind($LDAPLogin, password => $LDAPPassword, version => $LDAPVersion);
          } else {
            $mesg = $ldap->bind( version => $LDAPVersion );
          }
          $retcode = $mesg->code;
          if ($retcode) {
            mlog(0,"LDAP bind error: $retcode -- no LDAP-crosscheck is done") if $MaintenanceLog;
            undef $ldap;
          }
      }
  }
  
  my $expire_only;
  my $count;
  
  while (my ($k,$v)=each(%LDAPlist)) {
    $count++;
    &checkDBCon() unless $count % 100;
    $entry_count = 0;
    $expire_only = 0;
    $current_email = $k;
    my ($vt,$vl) = split(/ /o,$v);
    if($vl && $k !~ /^@/o) {  # do VRFY
        if ($DoVRFY && $CanUseNetSMTP) {
            mlog(0,"info: VRFY-crosscheck on $k") if $MaintenanceLog >= 2;
            my ($domain) = $k =~ /[^@]+\@([^@]+)/o;
            my $MTA = &matchHashKey('DomainVRFYMTA',lc $domain);
            $MTA = &matchHashKey('FlatVRFYMTA',lc "\@$domain") unless $MTA;
            $expire_only = 1;
            eval{
            $expire_only = 0;
            my $vrfy;
            my $expn;
            my $smtp = Net::SMTP->new($MTA,
                                 Hello => $myName,
                                 Timeout => $timeout),
                                 getLocalAddress('SMTP',$MTA);

            if ($smtp) {
                $forceRCPTTO = ($VRFYforceRCPTTO && $MTA =~ /$VFRTRE/) ? 1 : 0;
                if (! $forceRCPTTO) {
                    my $help = $smtp->help();
                    my $canvrfy = $help =~ /VRFY/io;
                    my $canexpn = $help =~ /EXPN/io;
                    if ($canvrfy) {$vrfy = $smtp->verify($k) ? 1 : $smtp->verify("\"$k\"");}
                    if ($canexpn && ! $vrfy) {$expn = scalar($smtp->expand($k)) ? 1 : scalar($smtp->expand("\"$k\""));}
                }
                if (!$expn && !$vrfy) {
                    if ($smtp->mail('postmaster@'.$myName)) {
                        $vrfy = $smtp->to($k);
                    }
                }
                $smtp->quit;
                $entry_count = $vrfy || $expn;
            }
            } if $MTA;
            if ($@) {
               mlog(0,"error: VRFY failed on host $MTA - $@");
               $expire_only = 1;
            }
        } else {
            $expire_only = 2;
        }
    } elsif ($ldap && $k !~ /^@/o) {   # do LDAP for addresses not for domains
        $expire_only = 0;
        mlog(0,"info: LDAP-crosscheck on $k") if $MaintenanceLog >= 2;
        $current_email =~ tr/A-Z/a-z/;
        $at_position = index($current_email, '@');
        $current_username = substr($current_email, 0, $at_position);
        $current_domain = substr($current_email, $at_position + 1);
        $ldapflt = $LDAPFilter;
        $ldapflt =~ s/EMAILADDRESS/$current_email/go;
        $ldapflt =~ s/USERNAME/$current_username/go;
        $ldapflt =~ s/DOMAIN/$current_domain/go;
        $ldaproot = $LDAPRoot;
        $ldaproot =~ s/DOMAIN/$current_domain/go;
# perform a search
        $mesg = $ldap->search(base   => $ldaproot,
                              filter => $ldapflt,
                              attrs => ['cn'],
                              sizelimit => 1
                              );
        $retcode = $mesg->code;
        if($retcode > 0 && $retcode != 4) {
          mlog(0,"LDAP search error: $retcode") if $MaintenanceLog;
          $expire_only = 1;
        }
        $entry_count = $expire_only ? 0 : $mesg->count;
    } else {
        $expire_only = 2;
    }

    if ($entry_count && exists $PBTrap{$k}) {
        pbTrapDelete($k);
        mlog(0,"info: TrapAddess $k removed") if $MaintenanceLog;
    }

    if (! $entry_count && ! $expire_only) { # entry was not found on LDAP/VRFY-server -> delete the cache entry
       delete($LDAPlist{$k});
       mlog(0,"LDAP/VRFY-crosscheck: $k not found and removed from LDAPlist") if $MaintenanceLog;
       d("LDAP/VRFY-crosscheck: $k removed from LDAPlist - Results $ldapflt: $entry_count : $retmsg");
    } elsif ($expire_only == 1 && $MaxLDAPlistDays && $vt + $MaxLDAPlistDays * 24 * 3600 < $t) { # entry is to old -> delete the cache entry
       delete($LDAPlist{$k});
       mlog(0,"LDAP/VRFY-crosscheck: $k removed from LDAPlist - entry is older than $MaxLDAPlistDays days") if $MaintenanceLog;
       d("LDAP/VRFY-crosscheck: $k removed from LDAPlist - entry is older than $MaxLDAPlistDays days");
    } elsif ($ldLDAPFilter && $expire_only == 2) {
       delete($LDAPlist{$k});
       mlog(0,"LDAP-crosscheck: $k domain entry removed from LDAPlist") if $MaintenanceLog;
       d("LDAP-crosscheck: $k domain removed from LDAPlist");
    }
  }
  $mesg = $ldap->unbind if $ldap;  # take down session
  mlog(0,"LDAP/VRFY-crosscheck finished") if $MaintenanceLog;
  &SaveLDAPlist();
}
