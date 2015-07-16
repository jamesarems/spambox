#line 1 "sub main::SearchBombW"
package main; sub SearchBombW {
    my ($name, $srch)=@_;
    
    $incFound = '';
    $weightMatch = '';
    my %Bombs = &BombWeight(0,$srch,$name );
    if ($Bombs{count}) {
        my $match = &SearchBomb($name, $$srch);
        $weightMatch = encodeHTMLEntities($match) if (! $weightMatch);
        return 'highest match: "' . "$Bombs{matchlength}" . encodeHTMLEntities($Bombs{highnam}) . '" with valence: ' . $Bombs{highval} . ' - PB value = ' . $Bombs{sum};
    }
    return;
}
