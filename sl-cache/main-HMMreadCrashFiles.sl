#line 1 "sub main::HMMreadCrashFiles"
package main; sub HMMreadCrashFiles {
    return unless $enableCrashAnalyzer;
    print "\t\t\t\t[OK]\nstarting crash analyzer   ";
    mlog(0,"warning: 'discarded' is not configured - crash analyzer is switched off in SMTP-workers") if (! $discarded);
    my @files;
    my @lines;
    my @allstarts;
    my $file;
    my $filenum = 0;
    my $dir = "$base/crash_repo";
    @files = reverse $unicodeDH->($dir);
    while (@files) {
        my @starts;
        my $dataseen;
        my $headerseen;
        $file = shift @files;
        next if -d $file;
        $file = "$dir/$file";
        $open->(my $FH,'<', $file) or next;
        my @filelines;
        while (my $line = (<$FH>)) {
            $line =~ s/\r|\n//og;               # strip unneeded strings and lines, and make word lists
            last unless $line; # header only
            $line = HMMcleanUp(lc $line);
            next unless $line;
            $headerseen = 1 if $dataseen;
            $dataseen = 1 if $line =~ /^data\s*$/io;
            my @words = split(/\s+/o, $line);
            push @starts, $words[0];
            push @filelines, @words;
        }
        $FH->close;
        if ($headerseen) {
            push @lines,@filelines;
            push @allstarts,@starts;
            $filenum++;
        } else {
            $unlink->($file);
            mlog(0,"info: removed too short file $file from crash respository") if $MaintenanceLog > 1;
        }

        last if $filenum > $NumComWorkers * 10; # prevent too much memory usage for HMM
    }
    if (@files) {
        mlog(0,"info: the following files in the crash respository are ignored: \n".join("\n",@files));
    }
    if (! @lines) {
        mlog(0,"info: no lines from crash respository left for a Hidden Markov Model");
        return;
    }
    my $chain = ASSP::MarkovChain->new(longest => 6,
                                       top => $CrashAnalyzerTopCount
                                       );
    if (! ref $chain) {
        mlog(0,"info: unable to create a Hidden Markov Model - $chain");
        return;
    }
    eval {
        $chain->seed(symbols => \@lines,
                     longest => 6
                   );
        @{$chain->{_start_states}} = @allstarts;
    };
    mlog(0,"info: unable to build a Hidden Markov Model - $@") and return if $@;

    mlog(0,"info: crash respository in $base/crash_repo is too small for a usable Hidden Markov Model") and return if $chain->longest_sequence < 6;
    my $symcount = scalar keys %{$chain->{totals}};
    mlog(0,"info: loaded $symcount Markov-Chains from crash respository") if $MaintenanceLog >= 2;
    mlog(0,"info: enabled traffic/header prescan for crash prevention");
    my $top10count = scalar keys %{$chain->{top10}};
    if ($MaintenanceLog && $top10count) {
        mlog(0,"info: the following are the top $top10count Markov-Chains from the HMM crash respository - possibly you can use some of them to build a 'preHeaderRe'");
        for (0..($top10count-1)) {
            my $sym = join(' ',split($chain->{seperator},$chain->{top10}{$_}));
            mlog(0,"info: Markov-Chain ($_) => '$sym' => occurrency count: ".$chain->{top10count}{$_});
        }
    }
    if ($MaintenanceLog > 2 && eval 'use Devel::Size();1;') {
        my $size = &formatDataSize((Devel::Size::total_size(\%{$chain->{totals}}) +
                                    Devel::Size::total_size(\%{$chain->{chains}}) +
                                    Devel::Size::total_size(\%{$chain->{top10}}) +
                                    Devel::Size::total_size(\%{$chain->{top10count}}) +
                                    Devel::Size::total_size(\@{$chain->{_start_states}}) +
                                    Devel::Size::total_size(\%{$chain->{_symbols}})
                                   ) * $NumComWorkers
                                  ,1);
        mlog(0,"info: HMM uses $size of memory");
    }
    return $chain;
}
