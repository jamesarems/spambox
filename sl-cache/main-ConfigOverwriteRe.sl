#line 1 "sub main::ConfigOverwriteRe"
package main; sub ConfigOverwriteRe {
    my $reMask = (  $WeightedReOverwrite{bombRe}
                  | $WeightedReOverwrite{bombSenderRe}
                  | $WeightedReOverwrite{bombHeaderRe}
                  | $WeightedReOverwrite{bombSubjectRe}
                  | $WeightedReOverwrite{bombCharSets}
                  | $WeightedReOverwrite{bombDataRe}
                  | $WeightedReOverwrite{bombSuspiciousRe}
                  | $WeightedReOverwrite{blackRe}
                  | $WeightedReOverwrite{scriptRe} );

    $bombReNPw    = $reMask & 1;
    $bombReWLw    = $reMask & 2;
    $bombReLocalw = $reMask & 4;
    $bombReISPIPw = $reMask & 8;

    $DoReversedNPw =  $WeightedReOverwrite{invalidPTRRe} & 1;
    $DoReversedWLw =  $WeightedReOverwrite{invalidPTRRe} & 2;

    $DoHeloNPw =  $WeightedReOverwrite{invalidFormatHeloRe} & 1;
    $DoHeloWLw =  $WeightedReOverwrite{invalidFormatHeloRe} & 2;
}
