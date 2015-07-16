#line 1 "sub main::showBDBstatus"
package main; sub showBDBstatus {
    my @hashes = @_;
    while (shift @hashes) {
        unless (exists $BerkeleyDBHashes{$_}) {
            mlog(0,"info: showBDBstatus - hash $_ is not a BerkeleyDB hash");
            next;
        }
        my $dbo = $_ . 'Object';
        $dbo = $_ . 'Obj' unless defined ${$dbo};
        if (! defined ${$dbo} ) {
            mlog(0,"hash: $_ is not tied");
            return;
        }
        mlog(0,"BDB statistic for BerkeleDB hash $_ on $dbo");
        my $statref;
        if ("$$dbo" =~ /spambox::/io) {
            eval (<<'EOT');
                 $statref = ${$dbo}->{hashobj}->db_stat();
EOT
        } else {
            eval (<<'EOT');
                 $statref = ${$dbo}->db_stat();
EOT
        }
        my $out = "\n";
        foreach (sort keys %{$statref}) {
            $out .= $_ . (' ' x (16 - length($_))) . ": ${$statref}{$_}\n";
        }
        mlog(0,$out);
        mlog(0, "lock status for BerkleyDB hash $_ on $dbo");
        if ($VerBerkeleyDB lt '0.42') {
            ${${$dbo}}[1]->lock_stat_print;
        } else {
            ${$dbo}->Env->lock_stat_print;
        }
    }
}
