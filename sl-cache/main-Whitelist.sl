#line 1 "sub main::Whitelist"
package main; sub Whitelist {
    my($mf,$to,$action)=@_;
    d("Whitelist $mf,$to,$action");
    @WhitelistResult = ();
    $mf = batv_remove_tag(0,lc $mf,'') if $mf;
    $to = batv_remove_tag(0,lc $to,'') if $to;
    $to =~ s/^,//o;
    my $toDomain;
    $toDomain = $1 if $to =~ /(\@$EmailDomainRe)$/o;
    $to = undef if $to =~ /^\@$EmailDomainRe$/o;
    $action = lc $action;
    my $globWhite = $WhitelistPrivacyLevel&&defined${chr(ord(",")<< 1)}?($toDomain&&defined${chr(ord(",")<< 1)}?($WhitelistPrivacyLevel==2?undef:$Whitelist{"$mf,$toDomain"}):undef):$Whitelist{$mf};
    my $persWhite = $to?$Whitelist{"$mf,$to"}:undef;
    my $time = time;
    if (! $action) {                  # is there any Whitelist entry
        return 0 if $persWhite > 9999999999;       # a deleted personal
        return ($persWhite or $globWhite) ? 1 : 0;      # a personal or global
    } elsif ($action eq 'add') {
        if ($to) {$Whitelist{"$mf,$to"} = $time; push @WhitelistResult, "$mf,$to added to Whitelist<br />";};
        if ($toDomain) {$Whitelist{"$mf,$toDomain"} = $time ; push @WhitelistResult, "$mf,$toDomain added to Whitelist<br />";};
        $Whitelist{$mf} = $time;
        push @WhitelistResult, "$mf added to Whitelist<br />";
        return;
    } elsif ($action eq 'delete') {
        if ($to) {
            push @WhitelistResult, "$mf,$to removed from Whitelist<br />" if $Whitelist{"$mf,$to"} < 9999999999;
            $Whitelist{"$mf,$to"} = $time + 9999999999;  # delete the personal
        } elsif ($toDomain) {
            push @WhitelistResult, "$mf,$toDomain removed from Whitelist<br />" if delete $Whitelist{"$mf,$toDomain"};
            ThreadMonitorMainLoop("delete Whitelist $mf,\*$toDomain");
            if ($DoSQL_LIKE && "$WhitelistObject" =~ /Tie\:\:RDBM/o) {
#                $toDomain =~ s/([_%])/:$1/go;
#                $mf =~ s/([_%])/:$1/go;
#                my $res = $WhitelistObject->rdbm_RunSTM("WLRDOM",
#"DELETE FROM $WhitelistObject->{table} WHERE $WhitelistObject->{key} LIKE $mf,\%$toDomain ESCAPE ':' AND $WhitelistObject->{value} < '9999999999'");
#                $res ||= 'NO';
#                push @WhitelistResult, "$res private records removed from Whitelist<br />"
                delete $Whitelist{"$mf,\*$toDomain"};
            } else {
                my $i;
                while (my ($k,$v) = each(%Whitelist)) {      # and not already removed personal
                    if ($k =~ /^\Q$mf\E,$EmailAdrRe\Q$toDomain\E$/) {
                        push @WhitelistResult, "k removed from Whitelist<br />" if delete $Whitelist{$k}; # $Whitelist{$k} < 9999999999 ???
                    }
                    unless (++$i % 1000) {
                        ThreadMonitorMainLoop("delete Whitelist $mf,\*$toDomain");
                        $WorkerLastAct{$WorkerNumber} = time if $WorkerNumber > 0 && $WorkerNumber < 10000;
                    }
                }
            }
        } else {
            push @WhitelistResult, "$mf removed from Whitelist<br />" if delete $Whitelist{$mf}; # delete the global entry;
            ThreadMonitorMainLoop("delete Whitelist $mf,*");
            if ($DoSQL_LIKE && "$WhitelistObject" =~ /Tie\:\:RDBM/o) {
#                $mf =~ s/([_%])/:$1/go;
#                my $res = $WhitelistObject->rdbm_RunSTM("WLRALL",
#"DELETE FROM $WhitelistObject->{table} WHERE $WhitelistObject->{key} LIKE $mf,\% ESCAPE ':' AND $WhitelistObject->{value} < '9999999999'");
#                $res ||= 'NO';
#                push @WhitelistResult, "$res private records removed from Whitelist<br />"
                delete $Whitelist{"$mf,*"};
            } else {
                my $i;
                while (my ($k,$v) = each(%Whitelist)) {      # and not already removed personal
                    if ($k =~ /^\Q$mf\E,/) {
                        push @WhitelistResult, "$k removed from Whitelist<br />" if delete $Whitelist{$k}; # $Whitelist{$k} < 9999999999 ???
                    }
                    unless (++$i % 1000) {
                        ThreadMonitorMainLoop("delete Whitelist $mf,*");
                        $WorkerLastAct{$WorkerNumber} = time if $WorkerNumber > 0 && $WorkerNumber < 10000;
                    }
                }
            }
        }
    }
}
