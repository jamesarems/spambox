#line 1 "sub main::configChangeCpuAffinity"
package main; sub configChangeCpuAffinity {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: Cpu Affinity updated from '$old' to '$new'") unless ($init || $new eq $old);
    $new ||= (unpack("A1",${'X'})-3);
    if ($CanUseSysCpuAffinity) {
        if ($new ne $old) {
            $Config{spamboxCpuAffinity} = $spamboxCpuAffinity = $new unless $WorkerNumber;
            my @oldcpus = eval{Sys::CpuAffinity::getAffinity($$);};
            my @newcpus = split(/[ ,]+/o,$new);
            my $success = eval{Sys::CpuAffinity::setAffinity($$, ($new == (unpack("A1",${'X'})-3)) ? $new : \@newcpus );};
            if ($success) {
                @newcpus = eval{Sys::CpuAffinity::getAffinity($$);};
                mlog(0,"info: CPU Affinity changed for $WorkerName from '@oldcpus' to '@newcpus'") if (join(',',sort @oldcpus) ne join(',', sort @newcpus));
                @currentCpuAffinity = @newcpus;
                my $num = scalar(@newcpus);
                return '' if $num > 3;
                if ($num > 2) {
                    mlog(0,"info: spambox uses $num CPU's - at least 4 CPU's are recommended") if $WorkerName eq 'init';
                    return "info: spambox uses $num CPU's - at least 4 CPU's are recommended";
                } elsif ($num > 1) {
                    mlog(0,"warning: spambox uses $num CPU's - at least 4 CPU's are recommended") if $WorkerName eq 'init';
                    return "warning: spambox uses $num CPU's - at least 4 CPU's are recommended";
                } else {
                    mlog(0,"ERROR: spambox uses only $num CPU's - THIS WILL NOT WORK - at least 4 CPU's are recommended") unless $WorkerNumber;
                    return "<span class=\"negative\">ERROR: spambox uses only $num CPU's - THIS WILL NOT WORK - at least 4 CPU's are recommended!</span>";
                }
            } else {
                $Config{spamboxCpuAffinity} = $spamboxCpuAffinity = $old;
                return "<span class=\"negative\">failed to set CPU Affinity to '@newcpus' in worker $WorkerName! - $@</span>";
            }
        } else {
            return '';
        }
    }
    return "<span class=\"negative\"> - module Sys\:\:CpuAffinity version 1.05 is required!</span>";
}
