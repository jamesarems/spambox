#line 1 "sub main::updateLDAPHost"
package main; sub updateLDAPHost {my ($name, $old, $new, $init)=@_;
    my $ldap;
    my $ldaplist;
    my @ldaplist;
    mlog(0,"AdminUpdate: LDAP Hosts updated from '$old' to '$new'") unless $init || $new eq $old;
    $LDAPHost=$new;
    $Config{$name} = $new;
    if($LDAPHost && $CanUseLDAP && $DoLDAP) {
        @ldaplist = split(/\|/o,$LDAPHost);
        $ldaplist = \@ldaplist;
        mlog(0,"checking LDAP server at $LDAPHost -- ");
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

        if(! $ldap || $@) {
            mlog(0,"AdminUpdate: error couldn't contact LDAP server at $LDAPHost -- $@");
            if (!$init) {
                return ' & LDAP not activated';
            } else {
                return '';
            }
        } else {
            mlog(0,"AdminUpdate: LDAP server at $LDAPHost contacted -- ");
            if (!$init) {
                return ' & LDAP activated';
            } else {
                return '';
            }
        }
    }
}
