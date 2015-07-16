#line 1 "sub main::ConfigMakeGroupRe"
package main; sub ConfigMakeGroupRe {
    my ($name, $old, $new, $init)=@_;
    mlog( 0, "adminupdate: $name changed from '$old' to '$new'" )
      unless $init || $new eq $old;
    my $fil; my $ofil; my $isdynamic;
    $fil = $1 if $new =~ /^ *file: *(.+)/io;
    $fil="$base/$fil" if $fil && $fil!~/^\Q$base\E/io;
    $ofil = $1 if $old =~ /^ *file: *(.+)/io;
    $ofil="$base/$ofil" if $ofil && $ofil!~/^\Q$base\E/io;
    delete $CryptFile{$ofil} if $ofil;
    $CryptFile{$fil} = 1 if $fil;
    if ($WorkerNumber > 0) {    # %GroupRE is shared and already set for Workers from MainThread
        $FileUpdate{"$fil$name"} = $FileUpdate{$fil} = ftime($fil);
        foreach my $group (keys %GroupWatch) {
            &ConfigCheckGroupWatch($group);
        }
        return;
    }
    ${$name} = $new unless $WorkerNumber;
    if ($init && $fil && !-e $fil) {
        &downloadHTTP($GroupsFileURL,
            $fil,
            0,
            "GroupsFile",5,9,2,1);
    }
    $new = checkOptionList( $new, $name, $init , 1);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    if (! $new) {
        %GroupRE = ();
        foreach my $group (keys %GroupWatch) {
            &ConfigCheckGroupWatch($group);
        }
        mlog(0,"info: no groups loaded from groupsfile $fil") if $MaintenanceLog > 1;
        return;
    }
    mlog(0,"info: loading groups from groupsfile $fil") if $MaintenanceLog;
    my @entry = split(/\|/o,$new);
    my $group;
    my %NewGroupRE;
    my $count = 0;
    my $ldapcnt = 0;
    my $execcnt = 0;
    my $continue;
    while (@entry) {
        my $e = shift @entry;
        $e =~ s/^\s*(.*)?\s*$/$1/o;
        $e =~ s/^[#;].*//o;
        next unless $e;
        if ($e =~ s/\s*\/\s*$//o) {
            $continue .= $e;
            next;
        }
        $e = $continue . $e;
        $continue = '';
        if ($e =~ /^\[\s*([^\]]+?)\s*\]$/o) {
            my $grp = $1;
            $count = 'NO' unless $count;
            my $s = ($count eq 'NO' or $count > 1) ? 's' : '';
            mlog(0,"info: group $group loaded with $count record$s") if $group && $MaintenanceLog;
            $count = 0;
            $ldapcnt = 0;
            $execcnt = 0;
            $group = $grp;
            next;
        }
        next unless $group;
        if ($e =~ /^ldap:\s*\{([^{}]*)\}\s*,\s*\{([^{}]*)\}\s*\{([^{}]*)\}\s*,\s*\{([^{}]*)\}\s*\{([^{}]*)\}$/io) {
            my $ldaphostdef = $1;
            my $userfilt = $2;
            my $userattr = $3;
            my $addrfilt = $4;
            my $addrattr = $5;
            $isdynamic = 1;
            my ($usercode,$addrcode);
            mlog(0,"info: LDAPList-query: <$1> , <$2> , <$3> , <$4> , <$5>") if $LDAPLog > 2;
            ($userfilt,$usercode) = split(/\s*<=\s*/o,$userfilt,2);
            ($addrfilt,$addrcode) = split(/\s*<=\s*/o,$addrfilt,2);
            $ldaphostdef =~ s/^\s*//o;
            $ldaphostdef =~ s/\s*$//o;
            my %queryattr;
            my %ldap ;
            if ($ldaphostdef) {
                for my $tag ('host','password', 'base', 'user') {
                    if ($ldaphostdef =~ /$tag\s*=>\s*(.)/i) {
                        my $sep = quotemeta($1);
                        $queryattr{$tag} = $1 if $ldaphostdef =~ s/$tag\s*=>\s*$sep([^$sep]*)$sep,?//i;
                    }
                }
                my %tldap = split(/\s*(?:,|=>)\s*/o,$ldaphostdef);
                while (my ($k,$v) = each %tldap) {
                    $ldap{lc $k} = $v;
                }
            }
            $ldap{host} =~ s/,/\|/go;
            $ldap{password} = $queryattr{password} if exists $queryattr{password};
            $ldap{base} = $queryattr{base} if exists $queryattr{base};
            $ldap{user} = $queryattr{user} if exists $queryattr{user};
            $ldap{ldapfilt} = $userfilt;
            $ldap{attr} = $userattr;
            $ldapcnt++;
            d("ConfigMakeGroupRe - $e");
            $e = '';
            if ($addrfilt and $addrattr) {
                foreach my $userid (&LDAPList(%ldap)) {
                    if ($usercode) {
                        $_ = $userid;
                        if (eval($usercode)) {
                            $userid = $_;
                        } elsif ($@) {
                            mlog(0,"error: running the user-filter-callback ($usercode) on ($userid) caused an exception - $@");
                            next;
                        } else {
                            mlog(0,"info: the user-filter-callback ($usercode) on ($userid) returned zero or undef - entry is ignored") if $LDAPLog > 2;
                            next;
                        }
                    }
                    next unless $userid;
                    my $tmpaddrfilt = $addrfilt;
                    my %attr = split(/[=,]/o,$userid);
                    while( my ($tag,$val) = (each %attr)) {
                        my $qtag = quotemeta($tag);
                        $tmpaddrfilt =~ s/$qtag\=\%USERID\%/$tag=$val/g;
                    }
                    $tmpaddrfilt =~ s/\%USERID\%/$userid/g;
                    $ldap{ldapfilt} = $tmpaddrfilt;
                    $ldap{attr} = $addrattr;
                    my @adr = &LDAPList(%ldap);
                    my @tadr;
                    if ($addrcode) {
                        for (@adr) {
                            if (eval($addrcode)) {
                                push @tadr, $_;
                            } elsif ($@) {
                                mlog(0,"error: running the address-filter-callback ($addrcode) on ($_) caused an exception - $@");
                                next;
                            } else {
                                mlog(0,"info: the address-filter-callback ($addrcode) on ($_) returned zero or undef - entry is ignored") if $LDAPLog > 2;
                                next;
                            }
                        }
                        @adr = @tadr;
                    }
                    @adr && $e && ($e .= '|');
                    $e .= join('|',@adr);
                }
            } else {
                my @adr;
                foreach my $userid (&LDAPList(%ldap)) {
                    if ($usercode) {
                        $_ = $userid;
                        if (eval($usercode)) {
                            $userid = $_;
                        } elsif ($@) {
                            mlog(0,"error: running the user-filter-callback ($usercode) on ($userid) caused an exception - $@");
                            next;
                        } else {
                            mlog(0,"info: the user-filter-callback ($usercode) on ($userid) returned zero or undef - entry is ignored") if $LDAPLog > 2;
                            next;
                        }
                    }
                    next unless $userid;
                    push @adr, $userid;
                }
                $e = join('|',@adr);
            }
            d("ConfigMakeGroupRe - result: $e");
            my $adr = () = $e =~ /([^\\]\|)/go;
            $adr = $e ? $adr + 1 : 'NO';
            my $es = ($adr eq 'NO' or $adr > 1) ? 'es' : '';
            mlog(0,"info: group $group loaded $adr address$es via LDAP(line $ldapcnt)") if $MaintenanceLog;
            next unless $e;
            $count += $adr;
        } elsif ($e =~ /^exec:\s*(.+)$/io) {
            my $cmd = $1;
            $isdynamic = 1;
            $execcnt++;
            d("ConfigMakeGroupRe - $e");
            $e = join('|',split(/\s*(?:\r?\n|,|\|)\s*/o,qx($cmd)));
            d("ConfigMakeGroupRe - result: $e");
            my $adr = () = $e =~ /([^\\]\|)/go;
            $adr = $e ? $adr + 1 : 'NO';
            my $es = ($adr eq 'NO' or $adr > 1) ? 'es' : '';
            mlog(0,"info: group $group loaded $adr address$es via exec(line $execcnt)") if $MaintenanceLog;
            next unless $e;
            $count += $adr;
        } else {
            $count++;
        }
        $NewGroupRE{$group} && ($NewGroupRE{$group} .= '|');
        $NewGroupRE{$group} .= $e;
    }
    $count = 'NO' unless $count;
    my $s = ($count eq 'NO' or $count > 1) ? 's' : '';
    mlog(0,"info: group $group loaded with $count record$s") if $group && $MaintenanceLog > 1;
    -d "$base/files/groups_export" or mkdir "$base/files/groups_export" ,0755;
    while ( ($group,my $re) = each %GroupRE) {
        unlink "$base/files/groups_export/$group.txt";
    }
    while ( ($group,my $re) = each %NewGroupRE) {
        if (open my $f,'>',"$base/files/groups_export/$group.txt") {
            binmode $f;
            $re =~ s/\|/\n/go;
            print $f $re;
            close $f;
        }
    }
    %GroupRE = %NewGroupRE;
    foreach my $group (keys %GroupWatch) {
        &ConfigCheckGroupWatch($group);
    }
    $GroupsDynamic = $isdynamic;
    return '';
}
