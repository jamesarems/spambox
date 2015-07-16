#line 1 "sub main::SNMPhandler"
package main; sub SNMPhandler {
    my ($handler, $registration_info, $request_info, $requests) = @_;

    my $request;
    if ($handler eq 'init') {
        mlog(0,"info: initalized SNMP OIDs") if $SNMPLog > 1;
    } else {
        mlog(0,"info: got snmp request") if $SNMPLog > 1;
        $MainThreadLoopWait = 0;
    }
    my $baseOID = NetSNMP::OID->new($SNMPBaseOID);
    my $minsubOID = '.1.0.0';
    my $minOID = $baseOID . $minsubOID;
    my $minOIDn = $SNMPBaseOID . $minsubOID;
    my $bid = '.'.join('.',$baseOID->to_array());
    $canSNMPAPI = 0;

    if ($handler eq 'init' or scalar @sortedOIDs != scalar keys %subOID) {
        delete $qs{ResetAllStats};
        delete $qs{ResetStats};
        &ConfigStats();
        %subOID = (); keys %subOID = 9216;
        %subOIDn = (); keys %subOIDn = 9216;
        &SNMPload_1();
        &SNMPload_2();
        &SNMPload_3();
        &SNMPload_4();
        &SNMPload_5();

        @sortedOIDs =  map { $_->[0] }
                       sort { NetSNMP::OID::compare( $main::a->[1], $main::b->[1] ) }
                       map { [ $_, NetSNMP::OID->new($SNMPBaseOID.$_) ] } keys %subOID;

        my $j = scalar @sortedOIDs;
        for (my $i = 0;$i < $j;$i++) {
             $subOIDn{$sortedOIDs[$i]} = $i;
        }
        mlog(0,"info: SNMP registered $j OIDs from $minOID to $maxOID") if $SNMPLog;
        if ($CreateMIB) {
            my $mibSUB;
            my $mibFile;
            if (open $mibFile , '<',"$base/SNMPmakeMIB.pl") {
                binmode $mibFile;
                while (<$mibFile>) {
                    $mibSUB .= $_;
                }
                close $mibFile;
                eval($mibSUB);
                mlog(0,"info: MIB failed - $@") if $@;
            }
            $mibSUB = '';
            if (open $mibFile , '<',"$base/SNMPmakeMRTG.pl") {
                binmode $mibFile;
                while (<$mibFile>) {
                    $mibSUB .= $_;
                }
                close $mibFile;
                eval($mibSUB);
                mlog(0,"info: MRTG-cfg failed - $@") if $@;
            }
        }
        return if $handler eq 'init';
    }

    my $retval = 0;
    for($request = $requests; $request; $request = $request->next()) {
        $retval = 1;
        my $oid = $request->getOID();
        my $sid = '.'.join('.',(NetSNMP::OID->new($oid))->to_array());
        $sid =~ s/^\Q$bid\E//;
        my ($ts,$tl) = $sid =~ /^\.?((\d+)\.\d+)/o;
        $tl ||= 1;
        if ($ts eq '1.30' && $subOIDLastLoad{$ts} < Time::HiRes::time() - 2) {
            &SNMPload_1_30();
        } elsif ($ts eq '1.31' && $subOIDLastLoad{$ts} < Time::HiRes::time() - 2) {
            &SNMPload_1_31();
        } elsif ($ts eq '1.32' && $subOIDLastLoad{$ts} < Time::HiRes::time() - 2) {
            &SNMPload_1_32();
        } elsif ($subOIDLastLoad{$tl} < Time::HiRes::time() - 2) {
            &{"SNMPload_$tl"};
        }
        my $mode = $request_info->getMode();
        my $value;
        if (exists $subOID{$sid}) {
            $value = SNMPderefVal($subOID{$sid});
        }

        if ($mode == $SNMPag{MODE_GET}) {
            if (exists $subOID{$sid}) {
                $request->setValue(SNMPVarType(\$value,$sid,0), $value);
                mlog(0,"info: snmp read request for OID - $oid - $sid - MODE_GET") if $SNMPLog == 3;
            } else {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOSUCHNAME});
                mlog(0,"info: snmp read request for unknown OID - $oid - $sid - MODE_GET") if $SNMPLog == 3;
            }
            mlog(0,"info: snmp MODE_GET - $oid") if $SNMPLog == 2;

        } elsif ($mode == $SNMPag{MODE_GETNEXT}) {
            if ($oid < NetSNMP::OID->new($minOID)) {
                $request->setOID(NetSNMP::OID->new($minOIDn));
                $value = SNMPderefVal($subOID{$minsubOID});
                $request->setValue(SNMPVarType(\$value,$minsubOID,0), $value);
                mlog(0,"info: snmp read request for OID - $oid - sid - MODE_GETNEXT - returned first available OID ".$minOID) if $SNMPLog == 3;
            } elsif ($oid >= NetSNMP::OID->new($maxOID)) {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOSUCHNAME});
                mlog(0,"info: snmp read request for unknown OID - $oid - $sid - MODE_GETNEXT") if $SNMPLog == 3;
            } else {
                my $j = scalar @sortedOIDs;
                my $i = $subOIDn{$sid};
                $i ||= 0;
                for ( ;$i < $j;$i++) {
                    next if $oid > NetSNMP::OID->new($baseOID.$sortedOIDs[$i]);
                    $i++ if $oid == NetSNMP::OID->new($baseOID.$sortedOIDs[$i]);
                    $request->setOID(NetSNMP::OID->new($SNMPBaseOID.$sortedOIDs[$i]));
                    $value = SNMPderefVal($subOID{$sortedOIDs[$i]});
                    $request->setValue(SNMPVarType(\$value,$sortedOIDs[$i],0), $value);
                    mlog(0,"info: snmp read request for OID - ". NetSNMP::OID->new($SNMPBaseOID.$sortedOIDs[$i])." - MODE_GETNEXT") if $SNMPLog == 3;
                    last;
                }
            }
            mlog(0,"info: snmp MODE_GETNEXT - $oid") if $SNMPLog == 2;

        } elsif ($mode == $SNMPag{MODE_GETBULK}) {
            my $answers = 0;
            if ($oid >= NetSNMP::OID->new($maxOID)) {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOSUCHNAME});
                mlog(0,"info: snmp read request for unknown OID - $oid - $sid - MODE_GETBULK") if $SNMPLog == 3;
            } else {
                my $repeat = $request->getRepeat();
                if ($oid < NetSNMP::OID->new($minOID)) {
                    $request->setOID(NetSNMP::OID->new($minOIDn));
                    $value = SNMPderefVal($subOID{$minsubOID});
                    $request->setValue(SNMPVarType(\$value,$minsubOID,0), $value);
                    mlog(0,"info: snmp read request for OID - $oid - $sid - MODE_GETBULK - used first available OID ".$minOID) if $SNMPLog == 3;
                    $request->setRepeat(--$repeat);
                    $answers++;
                }
                if ($repeat) {
                    my $j = scalar @sortedOIDs;
                    my $i = $subOIDn{$sid};
                    $i ||= 0;
                    for ( ;$i < $j;$i++) {
                        next if $oid > NetSNMP::OID->new($baseOID.$sortedOIDs[$i]);
                        $i++ if $oid == NetSNMP::OID->new($baseOID.$sortedOIDs[$i]);
                        $request->setOID(NetSNMP::OID->new($SNMPBaseOID.$sortedOIDs[$i]));
                        $value = SNMPderefVal($subOID{$sortedOIDs[$i]});
                        $request->setValue(SNMPVarType(\$value,$sortedOIDs[$i],0), $value);
                        $request->setRepeat(--$repeat);
                        $answers++;
                        last unless $repeat;
                    }
                }
            }
            mlog(0,"info: snmp MODE_GETBULK - $oid - $sid - $answers repeats") if $SNMPLog >= 2;

        } elsif ($mode == $SNMPag{MODE_SET_RESERVE1}) {
            if ($canSNMPAPI && $sid eq '.5.0.0') {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                mlog(0,"info: snmp init SNMPAPI request for OID - $oid - $sid - MODE_SET_RESERVE1") if $SNMPLog == 3;
            } elsif ($SNMPwriteable && exists $subOID2Conf{$sid}) {
                my $getValue = $request->getValue();
                my $q;
                $q = $1 if $getValue =~ s/^([\"\'])//o;
                $getValue =~ s/\Q$q\E$//o if $q;
                my $valid = $ConfigArray[$subOID2Conf{$sid}]->[5];
                if ($getValue =~ /$valid/i) {
                    $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                    mlog(0,"info: snmp init configuration change request for OID - $oid - $sid - MODE_SET_RESERVE1") if $SNMPLog == 3;
                } else {
                    $request->setError($request_info, $SNMPag{SNMP_ERR_WRONGVALUE});
                    mlog(0,"info: snmp configuration change request (MODE_SET_RESERVE1) failed for - ".$ConfigArray[$subOID2Conf{$sid}]->[0]." - invalid value - $getValue") if $SNMPLog;
                }
            } elsif (exists $subOID{$sid}) {
                $request->setError($request_info, $SNMPag{SNMP_ERR_READONLY});
                mlog(0,"info: snmp configuration change request for readonly OID - $oid - $sid - MODE_SET_RESERVE1") if $SNMPLog == 3;
            } else {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOSUCHNAME});
                mlog(0,"info: snmp change request for unknown OID - $oid - $sid - MODE_SET_RESERVE1") if $SNMPLog == 3;
            }
            mlog(0,"info: snmp MODE_SET_RESERVE1 - $oid") if $SNMPLog >= 2;

        } elsif ($mode == $SNMPag{MODE_SET_RESERVE2}) {
            if ($canSNMPAPI && $sid eq '.5.0.0') {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                mlog(0,"info: snmp init SNMPAPI request for OID - $oid - $sid - MODE_SET_RESERVE2") if $SNMPLog == 3;
            } elsif ($SNMPwriteable && exists $subOID2Conf{$sid}) {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                mlog(0,"info: snmp init configuration change request for OID - $oid - $sid - MODE_SET_RESERVE2") if $SNMPLog == 3;
            } elsif (exists $subOID{$sid}) {
                $request->setError($request_info, $SNMPag{SNMP_ERR_READONLY});
                mlog(0,"info: snmp configuration change request for readonly OID - $oid - $sid - MODE_SET_RESERVE2") if $SNMPLog == 3;
            } else {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOSUCHNAME});
                mlog(0,"info: snmp change request for unknown OID - $oid - $sid - MODE_SET_RESERVE2") if $SNMPLog == 3;
            }
            mlog(0,"info: snmp MODE_SET_RESERVE2 - $oid - $sid") if $SNMPLog >= 2;

        } elsif ($mode == $SNMPag{MODE_SET_ACTION}) {
            my $value;
            if ($canSNMPAPI && $sid eq '.5.0.0') {
                $value = $request->getValue();
                my $q;
                $q = $1 if $value =~ s/^([\"\'])//o;
                $value =~ s/\Q$q\E$//o if $q;
                mlog(0,"info: SNMPAPI request to execute : $value ") if $value && $SNMPLog > 1;
                if ($SNMPUser ne 'root' and $value =~ /^\s*(system|qx|\xB4[^\xB4]*\xB4)/o) {     # ... 3. back ticks B4
                   mlog(0,"warning: SNMPAPI request to execute system command: $value - is not allowed for non root users") ;
                   $request->setError($request_info, $SNMPag{SNMP_ERR_WRONGVALUE});
                   $subOID{'.5.0.0'} = '';
                   $lastSNMPAPIresult = '';
                } elsif (! $value) {
                   $subOID{'.5.0.0'} = '';
                   $lastSNMPAPIresult = '';
                   $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                   mlog(0,'info: SNMPAPI was reseted');
                } else {
                   $subOID{'.5.0.0'} = $value;
                   my ($sub,$parm) = &parseEval($value);
                   if ($sub) {
                       $sub =~ s/^\&//o;
                       $lastSNMPAPIresult = eval{$sub->(split(/\,/o,$parm));};
                   } else {
                       $lastSNMPAPIresult = eval($value);
                   }
                   if ($@) {
                       $request->setError($request_info, $SNMPag{SNMP_ERR_WRONGVALUE});
                       $lastSNMPAPIresult = 'error: - ' . $@;
                       mlog(0,"info: error executing SNMPAPI command: $value - $@") if $SNMPLog;
                   } else {
                       $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                       $lastSNMPAPIresult = 'success: - ' . &SNMPcleanHTML($lastSNMPAPIresult);
                       mlog(0,"info: successful executed SNMPAPI command: $value - return value was: $lastSNMPAPIresult") if $SNMPLog;
                   }
                }
            } elsif ($SNMPwriteable && exists $subOID2Conf{$sid}) {
                mlog(0,"info: snmp configuration change request - $oid - ".$ConfigArray[$subOID2Conf{$sid}]->[0]." - MODE_SET_ACTION") if $SNMPLog == 3;
                $qs{$ConfigArray[$subOID2Conf{$sid}]->[0]} = $request->getValue();
                my $q;
                $q = $1 if $qs{$ConfigArray[$subOID2Conf{$sid}]->[0]} =~ s/^([\"\'])//o;
                $qs{$ConfigArray[$subOID2Conf{$sid}]->[0]} =~ s/\Q$q\E$//o if $q;
                $ActWebSess = 'SNMP';
                $WebIP{$ActWebSess}->{user} = $SNMPUser;
                my $error = checkUpdate($ConfigArray[$subOID2Conf{$sid}]->[0],$ConfigArray[$subOID2Conf{$sid}]->[5],$ConfigArray[$subOID2Conf{$sid}]->[6],$ConfigArray[$subOID2Conf{$sid}]->[1]);
                if ($error =~ /span class.+?negative/o) {
                    $error =~ s/<b>(.+?)<\/b>/$1/o;
                    $request->setError($request_info, $SNMPag{SNMP_ERR_WRONGVALUE});
                    mlog(0,"info: snmp configuration change request failed for - ".$ConfigArray[$subOID2Conf{$sid}]->[0]." - ". $error) if $SNMPLog;
                } elsif ($error =~ /span class.+?positive/o) {
                    $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                    my $text = (exists $cryptConfigVars{$ConfigArray[$subOID2Conf{$sid}]->[0]}) ? '' : " to ". $qs{$ConfigArray[$subOID2Conf{$sid}]->[0]};
                    mlog(0,"info: snmp changed - ".$ConfigArray[$subOID2Conf{$sid}]->[0].$text) if $SNMPLog;
                } else {
                    $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
                    mlog(0,"info: snmp unchanged - ".$ConfigArray[$subOID2Conf{$sid}]->[0]." - ". $qs{$ConfigArray[$subOID2Conf{$sid}]->[0]}) if $SNMPLog > 1;
                }
                delete $qs{$ConfigArray[$subOID2Conf{$sid}]->[0]};
            } elsif (exists $subOID{$sid}) {
                $request->setError($request_info, $SNMPag{SNMP_ERR_READONLY});
                mlog(0,"info: snmp configuration change request for readonly OID - $oid - $sid - MODE_SET_ACTION") if $SNMPLog == 3;
            } else {
                $request->setError($request_info, $SNMPag{SNMP_ERR_NOSUCHNAME});
                mlog(0,"info: snmp change request for unknown OID - $oid - $sid - MODE_SET_ACTION") if $SNMPLog == 3;
            }
            mlog(0,"info: snmp MODE_SET_ACTION - $oid") if $SNMPLog == 2;

        } elsif ($mode == $SNMPag{MODE_SET_UNDO}) {
            $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
            mlog(0,"info: snmp ignored MODE_SET_UNDO request for OID - $oid - $sid") if $SNMPLog >= 2;

        } elsif ($mode == $SNMPag{MODE_SET_COMMIT}) {
            $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
            mlog(0,"info: snmp ignored MODE_SET_COMMIT request for OID - $oid - $sid") if $SNMPLog >= 2;

        } elsif ($mode == $SNMPag{MODE_SET_FREE}) {
            $request->setError($request_info, $SNMPag{SNMP_ERR_NOERROR});
            mlog(0,"info: snmp ignored MODE_SET_FREE request for OID - $oid - $sid") if $SNMPLog >= 2;

        } else {
            while (my($k,$v) = each %SNMPag) {
                $mode != $v and next;
                $k =~ /SNMP_ERR_/o and next;
                $mode = $k;
                last;
            }
            $request->setError($request_info, $SNMPag{SNMP_ERR_GENERR});
            mlog(0,"info: snmp unsupported request $mode for OID - $oid - $sid") if $SNMPLog == 3;
        }
    }
    return $retval;
}
