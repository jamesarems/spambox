#line 1 "sub main::BayesWords"
package main; sub BayesWords {
    my ($text,$privat) = @_;
    my $domain = (eval('defined ${chr(ord(",") << ($DoPrivatSpamdb > 1))};')) ? lc $privat : '';
    $privat = (eval('defined ${chr(ord(",") << ($DoPrivatSpamdb & 1))};')) ? lc $privat : '';
    $domain =~ s/^[^\@]*\@/\@/o;
    my @t;
    my $dummy = '';
    my (%seen, $PrevWord, $CurWord, %got, $how);
    keys %seen = 1024;
    keys %got = 1024;
    $how = 1 if [caller(2)]->[3] =~ /AnalyzeText/o;
    $how = 2 if (!$how && [caller(1)]->[3] =~ /ConfigAnalyze/o);
    $text = \$dummy if @HmmBayWords;
    use re 'eval';
    local $^R;
    while (@HmmBayWords || eval {$$text =~ /([$BayesCont]{2,})(?{$1})/go}) {
        my @Words;
        (@Words = @HmmBayWords ? (shift @HmmBayWords) : BayesWordClean($^R)) or next;
        while (@Words) {
            $CurWord = substr(shift(@Words),0,37);
            next unless $CurWord;
            if (! $PrevWord) {
                $PrevWord = $CurWord;
                next ;
            }
            my $j="$PrevWord $CurWord";
            $PrevWord = $CurWord;
            next if (++$seen{$j} > 2); # first two occurances are significant
            if ($privat && (my $v = $Spamdb{"$privat $j"})) {
                $got{ "private: $j" } = $v if ($how);
                for(1...$BayesPrivatPrior) {push(@t,$v);}
                next;
            }
            if ($domain && (my $v = $Spamdb{"$domain $j"})) {
                $got{ "domain: $j" } = $v if ($how);
                for(1...$BayesDomainPrior) {push(@t,$v);}
                next;
            }
            if (my $v = $Spamdb{$j}) {
                $got{ $j } = $v if ($how);
                push(@t,$v);
            }
        }
    }
    return \@t,\%got;
}
