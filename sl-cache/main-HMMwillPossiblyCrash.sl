#line 1 "sub main::HMMwillPossiblyCrash"
package main; sub HMMwillPossiblyCrash {
    my ($fh,$buf) = @_;
    d('HMMwillPossiblyCrash');
    mlog(0,"info: crash detection is running") if $ConnectionLog >= 2;
    if (! $discarded && $WorkerNumber > 0) {
        mlog(0,"warning: 'discarded' is not configured - crash analyzer is switched off");
        return 0;
    }
    my @lines;
    @lines = split(/(?:\r?\n)+/o, $Con{$fh}->{crashbuf}) if $fh;
    push @lines, ref $buf ? split(/(?:\r?\n)+/o, $$buf) : split(/(?:\r?\n)+/o, $buf);
    pop @lines; # remove the empty header line
    my ($count,$value);
    my $lines;
    while (@lines) {
        my $line = shift @lines;            # strip unneeded strings and lines, and make word lists
        $line = HMMcleanUp(lc $line);
        next unless $line;
        my @tocheck = split(/\s+/o,$line);
        my $expected = pop @tocheck;
        next unless @tocheck;
        $lines++;
        my $length = 20;    # never set this to a value < 1
        my $div = $length / 5;
        $length = @tocheck + 5 if @tocheck > $length - 5;
        my @newness;
        mlog(0,"info: asking HMM for - '@tocheck' - our expected is '$expected'") if $ConnectionLog > 2;
        eval { @newness = $crashHMM->spew(length       => $length,
                                          complete     => @tocheck,
                                          strict_start => 0
                                         );
        };
        for (1..@tocheck) {shift @newness;}
        next unless @newness;
        mlog(0,"info: HMM answers - '@newness' - our expected is '$expected'") if $ConnectionLog > 2;
        my $new = @newness;
        my $seq = join($crashHMM->{seperator},@tocheck);
        my $sym = $seq.$crashHMM->{seperator}.$expected;
        $length = @tocheck + 5;
        if (@tocheck > 2 && $crashHMM->sequence_known($sym)) {
            $count++;
            my $val = ($length + $new/$div) * 2;
            $value += $val;
            mlog(0,"info: HMM added $val, this line is exactly known by HMM - @tocheck $expected") if $ConnectionLog >= 2;
        }
        while (@newness) {
            $new--;
            my $word = shift @newness;
            $sym = $seq.$crashHMM->{seperator}.$word;
            if ($word eq $expected && $crashHMM->sequence_known($seq)) {
                $count++;
                my %Symbols = $crashHMM->get_options($seq);
                my $w = $Symbols{$word} * 2;
                my $val = ($length + $new/$div) * ($w + 4);
                $value += $val;
                mlog(0,"info: HMM added $val, found exact match for - '@tocheck' + '$word'") if $ConnectionLog >= 2;
            } elsif ($word eq $expected) {
                $count++;
                my $val = $length + $new/$div;
                $value += $val;
                mlog(0,"info: HMM added $val, our expected word '$expected' found in HMM answer") if $ConnectionLog >= 2;
            }
            next unless $crashHMM->sequence_known($sym);
            if (scalar keys %{$crashHMM->{top10}}) {
                my %Symbols = $crashHMM->get_options($seq);
                next unless exists $Symbols{$word};
                my $top10 = scalar keys %{$crashHMM->{top10}};
                for (0..($top10 - 1)) {
                    if ($sym eq $crashHMM->{top10}{$_}) {
                        $count++;
                        my $val = ($length + $new/$div) * $crashHMM->{top10count}{$_} * $Symbols{$word};
                        $value += $val;
                        mlog(0,"info: HMM added $val, match found in top $top10 Markov-Chains for - '@tocheck' + '$word'") if $ConnectionLog >= 2;
                        last;
                    }
                }
            }
        }
    }
    my $limit = 4;
    return 0 unless $value;
    return 0 unless $count;
    if ($count < $lines / 8) {
        mlog($fh,"info: HMM = too less hit-count - result (v=$value,c=$count,l=$lines,f=$limit)") if $ConnectionLog;
        return 0;
    }
    $count = 3 if $count < 3; # reduce value if hits are less than 3
    my $detail = $ConnectionLog >= 2 ? " (v=$value,c=$count,l=$lines,f=$limit)" : '';
    $value = $value / ( $count * $limit );
    mlog($fh,"info: HMM = result $value$detail, would not block ( <= $limit )") if $value <= $limit && $ConnectionLog;
    if ($value > $limit) {
        my $np = ($Con{$fh}->{noprocessing} == 1) ? ' (noprocessing)' : '';
        my $text = ($CrashAnalyzerWouldBlock && $Con{$fh}->{noprocessing} != 1) ? '' : ' - but currently not$np - partial debug was switchted on';
        mlog($fh,"info: HMM = result $value$detail, block the mail ( > $limit )$text") if $ConnectionLog;
        if ($fh && (! $CrashAnalyzerWouldBlock || $Con{$fh}->{noprocessing} == 1)) {
            $Con{$fh}->{debug} = 1;
            $Con{$Con{$fh}->{friend}}->{debug} = 1 if ($Con{$fh}->{friend} && exists $Con{$Con{$fh}->{friend}});
            $ThreadDebug = 1;
        }
        return 1 if $CrashAnalyzerWouldBlock && $Con{$fh}->{noprocessing} != 1;
    }
    return 0;
}
