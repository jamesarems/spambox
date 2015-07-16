#line 1 "sub main::ConfigChangeSNMP"
package main; sub ConfigChangeSNMP {my ($name, $old, $new, $init)=@_;
    return if $WorkerNumber != 0;
    if ($new ne $old or $init) {
        if ($init) {
            delete $qs{ResetAllStats};
            delete $qs{ResetStats};
            my $d = &ConfigStats();
        }
        if ($SNMPagent) {eval{$SNMPagent->shutdown();};  $SNMPagent = undef;}

        if ($name eq 'SNMPBaseOID') {
            $SNMPBaseOID = $Config{SNMPBaseOID} = $new;
            mlog(0,"AdminUpdate: $name changed from $old to $new") unless $init;
            return ConfigChangeSNMP('SNMP','',$Config{SNMP},$init);
        }
        if ($name eq 'SNMPAgentXSocket') {
            $SNMPAgentXSocket = $Config{SNMPAgentXSocket} = $new;
            mlog(0,"AdminUpdate: $name changed from $old to $new") unless $init;
            return ConfigChangeSNMP('SNMPBaseOID','',$Config{SNMPBaseOID},$init);
        }
        if ($new) {
            return "<span class=\"negative\">module NetSNMP::agent is not installed or disabled</span>" unless $CanUseNetSNMPagent;
            
            if (
                eval('netsnmp_ds_set_string(NETSNMP_DS_APPLICATION_ID, NETSNMP_DS_AGENT_X_SOCKET,$SNMPAgentXSocket);1')
                &&
                eval{$SNMPagent = NetSNMP::agent->new(
                            # makes the agent read a my_agent_name.conf file
                            'Name' => "assp2_$myName",
                            'AgentX' => 1
                            );
                }
                &&
                eval{$SNMPagent->register("assp2-$myName", $SNMPBaseOID,\&SNMPhandler);}
                && ! $@
            ) {
                mlog(0,"AdminUpdate: $name changed from $old to $new - agentX started") unless $init;
                ${$name} = $Config{$name} = $new;
                &SNMPhandler('init') unless @sortedOIDs;
                return 'SNMP agentX started';
            } else {
                mlog(0,"AdminUpdate: error unable to register SNMP agentX - agentX stopped - $@")  if $SNMPLog;
                return '<span class="negative">unable to register SNMP agentX - SNMP agentX stopped</span>';
            }
        } else {
            mlog(0,"AdminUpdate: $name changed from $old to $new - agentX stopped") unless $init;
            ${$name} = $Config{$name} = $new;
            return '<span class="negative">SNMP agentX stopped</span>';
        }
    }
}
