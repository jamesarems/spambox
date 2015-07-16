#line 1 "sub main::SNMPStats"
package main; sub SNMPStats {
    my ($subOID_cs,$subOID_cts,$subOID_ct,$subOID_ctt,$subOID_css,$subOID_ctss) = @_;
    my %subh = (
                'currentstat'     => $subOID_cs,
                'cumulativestat'  => $subOID_cts,
                'currenttotal'    => $subOID_ct,
                'cumulativetotal' => $subOID_ctt,
                'currentscorestat'     => $subOID_css,
                'cumulativescorestat'  => $subOID_ctss
    );
    my $str = &ConfigStatsXml();
    my %st;
    while ($str =~ /<stat +name='(.+?)' type='(.+?)'>(.*?)<\/stat>/gso) {
        $st{$1}{$subh{$2}}=$3 if $subh{$2};
    }
    delete $st{memusage};
    my $i = 0;
    my $highOID;

    my $l;
    foreach my $k (keys %st) {
        $l = length($k) if $l < length($k);
    }

    foreach my $name (sort {(' ' x ($l - length($main::a)).$main::a) cmp (' ' x ($l - length($main::b)).$main::b)} keys %st) {
        foreach my $soid (sort {lc($main::a) cmp lc{$main::b}} keys %{$st{$name}}) {
            my $value = ${$st{$name}}{$soid};
            $value = 0 unless $value;
            $subOID{"$soid.$i.0"} = $value;
            my $li='.0';
            my $n = $name;
            $n = "mailCount" if $name eq 'Counter';
            if ($CreateMIB) {
                $subOID{"$soid.$i.1"} = $n;
                $li = '.1';
                if ($subOID_cs && exists $StatText{$name}) {
                    $subOID{"$soid.$i.2"} = $StatText{$name};
                    $li = '.2';
                }
                if ($subOID_css && exists $ScoreStatText{$name}) {
                    $subOID{"$soid.$i.2"} = $ScoreStatText{$name};
                    $li = '.2';
                }
            }
            $highOID = "$soid.$i$li" if NetSNMP::OID->new($SNMPBaseOID.$highOID) < NetSNMP::OID->new("$SNMPBaseOID$soid.$i$li");
        }
        $i++;
    }
    mlog(0,"info: SNMP read Stats") if $SNMPLog == 3;
    return $highOID;
}
