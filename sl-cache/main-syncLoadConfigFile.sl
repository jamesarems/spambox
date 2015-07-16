#line 1 "sub main::syncLoadConfigFile"
package main; sub syncLoadConfigFile {
    my $RCF;
    lock($syncWriteConfigLock);
    share %ConfigSync unless is_shared(%ConfigSync);
    while (my ($k,$v) = each %Config) {
        $ConfigSync{$k} = &share({});
        $ConfigSync{$k}->{sync_cfg} = -1;
        $ConfigSync{$k}->{sync_server} = &share({});
    }
    return 0 unless &syncCanSync();
    my ($fn) = $syncConfigFile =~ /^ *file:(.+)$/o;
    return 0 unless $fn;
    my $usedfn = $fn;
       (open($RCF,'<',"$base/$fn"))
    || (open($RCF,'<',"$base/$fn.new") && ($usedfn = "$fn.new"))
    || (open($RCF,'<',"$base/$fn.bak") && ($usedfn = "$fn.bak"))
    || (open($RCF,'<',"$base/$fn.bak.bak") && ($usedfn = "$fn.bak.bak"))
    || (open($RCF,'<',"$base/$fn.bak.bak.bak") && ($usedfn = "$fn.bak.bak.bak"))
    || (mlog(0,"error: unable to open file $fn or any backup version of this file") && return 0);
    d("syncLoadConfigFile - $usedfn");
    mlog(0,"warning: the synchronization configuration file '$usedfn' is used instead of '$fn', which is not available") if $usedfn =~ /(?:bak|new)$/o;
    mlog(0,"loading config synchronization configuration file '$usedfn'") if $MaintenanceLog;
    while (<$RCF>) {
        s/\r|\n//go;
        s/[#;].*//o;
        my ($k,$v) = split(/:=/o,$_,2);
        next unless $k;
        next if exists $neverShareCFG{$k};
        next unless exists $Config{$k};
        my @scfg = split(/\s*,\s*/o,$v);
        $ConfigSync{$k}->{sync_cfg} = shift @scfg || 0;
        if (! @scfg) {
            foreach my $se (split(/\|/o,$syncServer)) {
                push @scfg , "$se=1" if $ConfigSync{$k}->{sync_cfg};
            }
        }
        while (my $se = shift @scfg) {
            my ($server,$status) = split(/\s*\=\s*/o,$se);
            next unless $server;
            $status = 3 if (! $isShareMaster && $isShareSlave);
            $ConfigSync{$k}->{sync_server}->{$server} = $status;
        }
    }
    close $RCF;
    &syncWriteConfig();
    return 1;
}
