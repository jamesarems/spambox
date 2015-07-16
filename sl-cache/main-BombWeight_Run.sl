#line 1 "sub main::BombWeight_Run"
package main; sub BombWeight_Run {
    my ($fh,$t,$re) = @_;
    d("BombWeight - $re");
    my @text;
    my $rawtext = ref $t ? $$t : $t;
    my %weight = ();
    my %found = ();
    my $weightsum = 0;
    my $weightcount = 0;
    $maxBombSearchTime = 5 unless $maxBombSearchTime;
    $weightMatch = '';
    my $regex = ${$re.'RE'};
    my $itime = time;
    $addCharsets = 1 if $re eq 'bombCharSets';
    if ($re ne 'bombSubjectRe') {
       $rawtext =~ s/(<!--.+?)-->/$1/sgo;
       my $mimetext = cleanMIMEBody2UTF8(\$rawtext);
       if ($mimetext) {
           if ($re ne 'bombDataRe') {
               $text[0] = cleanMIMEHeader2UTF8(\$rawtext,0);
               $mimetext =~ s/\=(?:\015?\012|\015)//go;
               $mimetext = decHTMLent(\$mimetext);
           }
           $text[0] .= $mimetext;
       } else {
           $text[0] = decodeMimeWords2UTF8($rawtext);
       }
    } else {
       $text[0] = $rawtext;
    }
    unicodeNormalize(\$text[0]);
    undef $rawtext;
    $addCharsets = 0;
    if ($DoTransliterate) {
        my $t = transliterate(\$text[0], 1);
        push(@text,$t) if $t;
    }
    mlog($fh,"info: transliterated content will be checked for '$re'") if $text[1] && $BombLog > 1;
    if (   $re =~ /^(?:bomb(?:Suspicious|Header)?|black|test)Re$/o
        && $bombSkipHeaderTagRe
        && $bombSkipHeaderTagReRE !~ /$neverMatchRE/o)
    {
        my $found;
        for (0,1) {
            my $head;
            $head = $1 if $text[$_] =~ /^($HeaderRe+)/ois;
            if ($head && $head =~ s/(^|\n)$bombSkipHeaderTagReRE:$HeaderValueRe/$1/gis) {
                $text[$_] =~ s/^($HeaderRe+)/$head/ois;
                $found = 1;
            }
        }
        mlog(0,"info: $re: removed all mail header tags found for bombSkipHeaderTagRe") if $found && $BombLog > 1;
    }
    if ($re eq 'bombSubjectRe' && $maxSubjectLength) {
        my ($submaxlength,$maxlengthweight) = split(/\s*\=\>\s*/o,$maxSubjectLength);
        $maxlengthweight ||= ${$WeightedRe{$re}}[0];
        my $sublength = length($text[0]);
        if ($submaxlength && $sublength > $submaxlength) {
            if ($maxlengthweight) {
                $weightsum += $maxlengthweight;
                $weightcount++;
                $weight{highval} = $maxlengthweight;
                $weight{highnam} = "subject length($sublength) > max($submaxlength)";
                $found{$weight{highnam}} = $maxlengthweight;
                $weight{matchlength} = '';
            } else {
                mlog(0,"warning: maxSubjectLength is defined as '$maxSubjectLength' - but assp is unable to calculate a valid weight");
            }
            $text[0] = substr($text[0],0,$submaxlength);
            $text[1] = substr($text[1],0,$submaxlength) if $text[1];
            mlog($fh,"info: Subject exceeds $maxSubjectLength byte - the checked subject is trunked to $submaxlength byte") if $BombLog && $fh;
        }
    }
    if ($re eq 'bombSubjectRe' && $fh && exists($Con{$fh}) && $Con{$fh}->{RFC2047} && (my $weight = ${$WeightedRe{$re}}[0])) {
        $weightsum += $weight;
        my $reason = "undecoded subject contains non printable characters (RFC2047)";
        $weightcount++;
        if ($weight > $weight{highval}) {
            $weight{highval} = $weight;
            $weight{highnam} = $reason;
        }
        $found{$reason} = $weight;
        $weight{matchlength} = '';
    }
    my $text;
    eval {
      local $SIG{ALRM} = sub { die "__alarm__\n"; };
      alarm($maxBombSearchTime + 10);
      if ($re ne 'bombSubjectRe' or ($re eq 'bombSubjectRe' && $weightsum < $bombMaxPenaltyVal)) {
          do {
              &sigonTry(__LINE__) if $text;
              $text = shift @text;
              while (&sigoffTry(__LINE__) && $text =~ /($regex)/gs) {
                  my $subre = $1||$2;
                  my $matchlength = length($subre);
                  last if time - $itime >= $maxBombSearchTime;
                  my $w = &weightRe($WeightedRe{$re},$re,\$subre,$fh);
                  &sigonTry(__LINE__);
                  next unless $w;
                  $subre = substr($subre,0,$RegExLength < 5 ? 5 : $RegExLength) if $subre;
                  $subre = '[!empty string!]' unless $subre;
                  if ($subre =~ /^\s+$/o) {
                      my $spcount = length($subre);
                      $subre = "[!$spcount spaces only!]";
                  }
                  $subre =~ s/\s+/ /go;
                  next if ($found{lc($subre)} > 0 && $found{lc($subre)} >= $w);
                  next if ($found{lc($subre)} < 0 && $found{lc($subre)} <= $w);
                  $found{lc($subre)} = $w;
                  $weightsum += $w;
                  $weightcount++;
                  if (abs($w) >= abs($weight{highval})) {
                      $weight{highval} = $w;
                      $subre =~ s{([\x00-\x1F])}{sprintf("'hex %02X'", ord($1))}eog;
                      $weight{highnam} = $subre;
                      $weight{matchlength} = (length($subre) != $matchlength) ? "(matchlength:$matchlength) " : '';
                  }
                  &ThreadYield;
                  if ($fh && $bombMaxPenaltyVal && $weightsum >= $bombMaxPenaltyVal) {
                      &sigoffTry(__LINE__);
                      last;
                  }
              }
          } while (@text && !($fh && $bombMaxPenaltyVal && $weightsum >= $bombMaxPenaltyVal));
          alarm(0);
      }
    };
    $itime = time - $itime;
    if ($@) {
        alarm(0);
        if ( $@ =~ /__alarm__/o ) {
            mlog( $fh, "BombWeight: timed out in 'RE:$re' after $itime secs.", 1 );
        } else {
            mlog( $fh, "BombWeight: failed in 'RE:$re': $@", 1 );
        }
    }
    &sigonTry(__LINE__);
    @text = (); $text = undef;
    if ($itime > $maxBombSearchTime) {
        mlog($fh,"info: $re canceled after $itime s > maxBombSearchTime $maxBombSearchTime s") if $BombLog >= 2 && $fh;
    }
    return %weight if $weightcount == 0;
    $weight{sum} = $weightsum > $bombMaxPenaltyVal ? $bombMaxPenaltyVal : $weightsum;
    $weight{count} = $weightcount;
    mlogRe($fh,"PB $weight{sum}: for $weight{highnam}",$re,'spambomb') if $BombLog && $fh;
    mlog($fh,"$weight{highnam} : $weight{matchlength}$weight{highval} , count : $weightcount , sum : $weightsum , time : $itime s") if $BombLog >= 2 && $fh;
    $weight{highnam} = "$weight{matchlength}" . join ' , ', map{my $t = "'" . substr($_,0,$RegExLength < 5 ? 5 : $RegExLength) . " ($found{$_})'";$t;}
                          (sort {$found{$main::b} <=> $found{$main::a}} keys %found) if $BombLog >= 2;
    return %weight;
}
