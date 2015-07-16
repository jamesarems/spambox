#line 1 "sub main::syncWriteConfig"
package main; sub syncWriteConfig {
    my $new;
    my $newST;
    return 0 unless &syncCanSync();
    my ($fn) = $syncConfigFile =~ /^ *file:(.+)$/io;
    return 0 unless $fn;
    lock($syncWriteConfigLock);
    (open(my $RCF,'>',"$base/$fn.new")) or return 0;
    open(my $RCFST,'>',"$base/files/sync_failed.txt");
    d('syncWriteConfig');
    binmode $RCF;
    binmode $RCFST;
    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
        next if (! $c->[0] || @$c == 5);
        next if $ConfigSync{$c->[0]}->{sync_cfg} == -1;
        next if exists $neverShareCFG{$c->[0]};
        my $st;
        my $data = $c->[0] . ':=' . $ConfigSync{$c->[0]}->{sync_cfg};
        my $syncserver = $ConfigSync{$c->[0]}->{sync_server};
        while (my ($k,$v) = each %{$syncserver}) {
            $data .= ",$k=$v";
            $st = 1 if $v == 1;
        }
        $new .= "$data\n";
        $newST .= "$data\n" if $st;
    }
    print $RCF $new;
    close $RCF;
    if ($newST) {
        print $RCFST '# ' , &timestring() , ' The following configuration values are still out of sync:',"\n\n";
        print $RCFST $newST;
    } else {
        print $RCFST '# ' , &timestring() , ' All configuration values are still synchronized.';
    }
    close $RCFST;
    if (open $RCF,'<',"$base/$fn.bak") {
        binmode $RCF;
        my $bak = join('',<$RCF>);
        close $RCF;
        $new =~ s/\r|\n//go;
        $bak =~ s/\r|\n//go;
        if ($new eq $bak) {
            unlink "$base/$fn.new";
            return 1;
        }
    }
    unlink "$base/$fn.bak.bak.bak";
    rename "$base/$fn.bak.bak","$base/$fn.bak.bak.bak";
    rename "$base/$fn.bak","$base/$fn.bak.bak";
    rename "$base/$fn","$base/$fn.bak";
    rename "$base/$fn.new","$base/$fn";
    mlog(0,"syncCFG: saved sync configuration to $base/$fn") if $MaintenanceLog >= 2;
    $FileUpdate{"$base/$fn".'syncConfigFile'} = ftime("$base/$fn");
    return 1;
}
