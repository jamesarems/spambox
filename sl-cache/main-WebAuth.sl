#line 1 "sub main::WebAuth"
package main; sub WebAuth {
    my ($user,$password) = @_;
    return 0 unless exists $AdminUsers{$user};
    return 0 if $AdminUsersRight{"$user.user.disabled"};
    my $md5password = Digest::MD5::md5_hex($password);
    my $ret = eval {
    my @ldaphost = split(/\|/o,$AdminUsersRight{"$user.user.LDAPserver"});
    if ($CanUseLDAP && @ldaphost ) {
        my $ldaplist = \@ldaphost;
        my $scheme = 'ldap';
        my $ldap;

        eval{
        $scheme = 'ldaps' if ($AdminUsersRight{"$user.user.LDAPssl"} == 1 and $AvailIOSocketSSL);
        $ldap = Net::LDAP->new( $ldaplist,
                                timeout => $LDAPtimeout,
                                scheme => $scheme,
                                inet4 =>  1,
                                inet6 =>  $CanUseIOSocketINET6,
                                getLocalAddress('LDAP',$ldaplist->[0])
                              );
        $ldap->start_tls() if ($AdminUsersRight{"$user.user.LDAPssl"} == 2 && $AvailIOSocketSSL);
        };

        if(! $ldap) {
            mlog(0,"WebAuth: user $user - Couldn't contact LDAP server at @ldaphost, scheme $scheme -- try local password");
            return 1 if ($AdminUsers{$user} eq $md5password);
            return 0;
        }
        $ldap->debug(12) if $debug or $ThreadDebug;
        my $dn;
        if ($AdminUsersRight{"$user.user.LDAProot"}) {
            $dn = $AdminUsersRight{"$user.user.LDAProot"};
            $dn =~ s/USER/$user/go;
        } else {
            $dn = $user;
        }
        my $mesg = $ldap->bind($dn, password => $password,  version => $AdminUsersRight{"$user.user.LDAPversion"});
        my $retcode = $mesg->code;
        if ($retcode) {
            my $error = $mesg->error;
            mlog(0,"WebAuth: user $user - LDAP bind/auth error: $retcode - $error -- try local password",1);
            eval{$ldap->unbind;};
            return 1 if ($AdminUsers{$user} eq $md5password);
            return 0;
        }
        $ldap->unbind;
        $AdminUsers{$user} = $md5password;
        $AdminUsersRight{"$user.user.passwordLastChange"} = time;
        return 1;
    } else {
        return 1 if ($AdminUsers{$user} eq $md5password);
        mlog(0,"warning: wrong authentication for user $user from host $WebIP{$ActWebSess}->{ip}");
        return 0;
    }
    };
    if ($@) {
        my $error = $@;
        $error =~ s/\r|\n/ /go;
        mlog(0,"WebAuth: user $user - LDAP error: $error -- try local password",1);
        return 1 if ($AdminUsers{$user} eq $md5password);
        mlog(0,"warning: wrong authentication for user $user from host $WebIP{$ActWebSess}->{ip}");
        return 0;
    }
    return $ret;
}
