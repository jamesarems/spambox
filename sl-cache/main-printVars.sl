#line 1 "sub main::printVars"
package main; sub printVars {
    return unless $printVars;
    return unless $WorkerNumber == 0 or $WorkerNumber == 1 or $WorkerNumber > 999;
    &printVarsOn();
    my $maxrefs = 2;
    my $rcount;
    my $minfo;
    my $docount;
    my $d_dump;
    print "$WorkerName prints varables to $base/debug/var-$$-$WorkerNumber.txt\n";

    eval (<<'EOT');
    open my $f , ">$base/debug/var-$$-$WorkerNumber.txt";
    binmode $f;
    open my $r , ">$base/debug/var-$$-$WorkerNumber-refcnt.txt"  if $countRefs;
    binmode $r  if $countRefs;
    print $f "\n==================\n";
    print $f "Perl var SIZE summary";
    print $f "\n==================\n";

    our $count = 0;
    our %vars;
    sub psize {
        my $v = shift;
        return if $v=~ /^main::/o;
        return if $v=~ /^::(?:vars|count)/o;
        for (keys %$v) {
           if (/\:\:$/o) {
               &psize($v.$_);
           } else {
               my $t = '$' if defined ${$v.$_};
                  $t = '@' if defined @{$v.$_};
                  $t = '%' if defined %{$v.$_};
               next unless $t;
               my $size = Devel::Size::total_size(\${$v.$_}) if $t eq '$';
                  $size = Devel::Size::total_size(\@{$v.$_}) if $t eq '@';
                  $size = Devel::Size::total_size(\%{$v.$_}) if $t eq '%';
               $count+=$size;
               $v =~ s/^:://o;
               $vars{$t.$v.$_} = $size;
           }
        }
    }

    &psize('::');

    for (sort {$vars{$main::b}<=>$vars{$main::a}} (keys %vars)) {
        print $f $_ . ': ' . $vars{$_} . "\n";
    }

    print $f "\n\nmemory used by Perl variables: " . &formatNumDataSize($count) . "\n";
    print $f "\n==================\n";
    undef %vars;
    undef $count;

    print $f "\n==================\n";
OUTER:
    for my $symname (sort keys %main::)
    {
        $rcount = 0;
        $docount = 0;
        foreach my $k (keys %Refs2Count) {
            if ($symname =~ /$k/ig) {
                $docount = 1;
                last;
            }
        }
        $docount = 1 if (! scalar keys %Refs2Count && $countRefs);
        if (defined @$symname)
        {
            eval{$rcount = Devel::Peek::SvREFCNT(@$symname);} if $docount;
            print "\@$symname = $rcount\n" if $rcount > $maxrefs;
            print $r "\@$symname = $rcount\n" if $rcount > $maxrefs;
            Dump (@$symname) if $rcount > $maxrefs;
        }
        elsif (defined %$symname)
        {
            eval{$rcount = Devel::Peek::SvREFCNT(%$symname);} if $docount;
            print "\%$symname = $rcount\n" if $rcount > $maxrefs;
            print $r "\%$symname = $rcount\n" if $rcount > $maxrefs;
            Dump (%$symname) if $rcount > $maxrefs;
        }
        elsif (defined $$symname)
        {
            eval{$rcount = Devel::Peek::SvREFCNT($$symname);} if $docount;
            print "\$$symname = $rcount\n" if $rcount > $maxrefs;
            print $r "\$$symname = $rcount\n" if $rcount > $maxrefs;
            Dump ($$symname) if $rcount > $maxrefs;
        }
        if ( ! %Vars2Print && $rcount <= $maxrefs) {

            # ignore some data that we don't care about:
            next if $symname eq 'SIG';
            next if $symname =~ /FileUpdate/io;
            next if $symname =~ /env/io;
            next if $symname =~ /grip/io;
            next if $symname =~ /config/io;
            next if $symname eq '!';
            next if $symname eq 'AllStats';
            next if $symname =~ /^Carp:/io;
            next if $symname =~ /^AF_/io;
            next if $symname =~ /^Avail/io;
            next if $symname =~ /^can/io;
            next if $symname =~ /^use/io;
            next if $symname =~ /^BG_/io;
            next if $symname =~ /^DB_/io;
            next if $symname =~ /^FG_/io;
            next if $symname =~ /^PF_/io;
            next if $symname =~ /^rb_/io;
            next if $symname =~ /^RC_/io;
            next if $symname =~ /RE$/o;
            next if $symname =~ /Re$/o;
            next if $symname =~ /^SO_/io;
            next if $symname =~ /^SERVICE/io;
            next if exists $Config{$symname};
            next if $symname eq 'OldStats';
            next if $symname eq 'Stats';
            next if $symname =~ /^ver/io;
            next if $symname =~ /^Win32/io;
            next if $symname =~ /^_</i;
            next if $symname =~ /^z_/i;
            next if $symname =~ /^header/io;
            next if $symname =~ /^lock/io;
#            next if $symname =~ /^main:/o;
            next if $symname =~ /utf8:/o;
            next if $symname =~ /CONSOLE_COLORS/o;
            next if $symname =~ /Compress:/o;
            next if $symname =~ /Cwd:/o;
#            next if $symname =~ /::/o;
            next if $symname =~ /ModuleList/io;
            next if $symname =~ /ModuleStat/io;
            next if $symname =~ /NavMenu/io;
            next if $symname =~ /PossibleOptionFiles/io;
            next if $symname =~ /RealTimeLog/io;
            next if $symname =~ /failedTable/io;
            next if $symname =~ /footers/io;
            next if $symname =~ /Group/io;
            next if $symname =~ /kudos/io;
            next if $symname =~ /object$/io;
            next if $symname =~ /^batv/io;
            next if $symname =~ /^DB/o;
            next if $symname =~ /^RecRepRegex/o;
            next if $symname =~ /^RunTaskNow/o;
            next if $symname =~ /^msgid_secrets/o;
            next if $symname =~ /ARNING_BITS/o;
            next if $symname =~ /TRIE_MAXBUF/o;
            next if $symname eq 'head';
            next if $symname eq 'qs';
            next if $symname eq 'Refs2Count';
            next if $symname eq 'Vars2Print';
            next if $symname eq 'Charsets';
            next if $symname eq 'Day_to_Text';
            next if $symname eq 'Month_to_Text';
            next if $symname eq 'Spamfiles';
            next if $symname eq 'SuspiciousVirusWeight';
            next if $symname eq 'blackReWeight';

            next if length($symname) < 2;

            foreach my $dbGroup (@GroupList) {
                foreach my $dbGroupEntry (@$dbGroup) {
                    my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/,$dbGroupEntry);
                    next OUTER if $KeyName eq $symname;
                }
            }
            next if $$symname =~ /^aaaaaaaaaaaaaaaa/io;
            next if $$symname =~ /^\(\?\-/o;
        } else {
            if ($rcount <= $maxrefs) {
                my $found = 0;
                foreach my $k (keys %Vars2Print) {
                    if ($symname =~ /$k/ig) {
                        $found = 1;
                        last;
                    }
                }
                next if (! $found);
            }
        }
        $d_dump = $rcount > $maxrefs ? "refcount($rcount)" : '';
        if (defined @$symname)
        {
            print $f "\@$symname: $d_dump\n";
            print $f Dumper(@$symname);
        }
        elsif (defined %$symname)
        {
            print $f "\%$symname: $d_dump\n";
            print $f Dumper(%$symname);
        }
        elsif (defined $$symname)
        {
            print $f "\$$symname: $d_dump \"$$symname\"\n";
            if ($symname eq 'writable' or $symname eq 'readable') {
                print $f Dumper($$symname->handles());
            }
        }
        else
        {
            next;
        }
    }
    print $f "\n==================\n";
    close $f;
    close $r if $countRefs;

EOT
}
