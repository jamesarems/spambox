#line 1 "sub main::localFrequencyNotOK_Run"
package main; sub localFrequencyNotOK_Run {
    my $fh = shift;
    my $this=$Con{$fh};
    d('localFrequencyNotOK');

    return 0 unless $this->{mailfrom};
    return 0 unless $this->{relayok};
    return 0 if ($this->{noprocessing} & 1);
    my ($to) = $this->{rcpt} =~ /(\S+)/o;
    my $mf = batv_remove_tag(0,$this->{mailfrom},'');
    return 0 if matchSL( [$to,$mf], 'EmailAdmins' );
    return 0 if lc($to) eq lc($EmailFrom);
    return 0 if lc($mf) eq lc($EmailFrom);

    return 0 if ($LocalFrequencyOnly && ! &matchSL($mf,'LocalFrequencyOnly'));
    return 0 if ( matchSL($mf,'NoLocalFrequency'));
    return 0 if ( matchIP( $this->{ip}, 'NoLocalFrequencyIP', 0, 1 ));

    my $time = time;
    my $numrcpt;
    my $firsttime;
    my $data;

    my %F = split(/ /o,$localFrequencyCache{$mf});
    my $i;
    foreach (sort keys %F) {
        if ($_ + $LocalFrequencyInt  < $time) {
            delete $F{$_};
            next;
        } else {
            $numrcpt += $F{$_};
            $firsttime = $_ if $i < 1;
        }
        $i++;
    }
    foreach (sort keys %F) {
        $data .= "$_ $F{$_} ";
    }
    $firsttime = $time unless $firsttime;
    $localFrequencyCache{$mf} = $data . "$time $this->{numrcpt}";
    $numrcpt += $this->{numrcpt};
    return 0 if $numrcpt < $LocalFrequencyNumRcpt;
    return $firsttime + $LocalFrequencyInt;
}
