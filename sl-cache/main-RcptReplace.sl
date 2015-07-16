#line 1 "sub main::RcptReplace"
package main; sub RcptReplace {
  my ($recpt,$sender,$RecRepRegex) = @_;
  my $new = $recpt;
  my @new;
  my @ret;
  $ret[0] = "result";
  my $k;
  my $v;
  my $jmptarget;
  my $sendertext;

  if ($sender) {
    $sendertext = "for sender $sender";
  } else {
    $sendertext = "for all senders";
  }

  push(@ret,"try to replace $recpt $sendertext with rules in configuration<br />");

  foreach (sort(keys(%$RecRepRegex))) {
    $k = $_;
    if ($jmptarget && $k ne $jmptarget) {
       next;
    } else {
       $jmptarget = '';
    }
    $v = $$RecRepRegex{$k};
    my ($type,$toregex,$replregex,$sendregex,$nextrule,$jump) = split(/<=>/o,$v);
    $sendregex = '*' if ($sendregex eq '' && ($type eq 'S' || $type eq ''));
    $sendregex = '.*' if ($sendregex eq '*' && $type eq 'R');
    $type = uc($type);
    if ($type eq 'S' || $type eq '') {
      $toregex   = RcptRegexMake($toregex,1);
      $replregex = RcptRegexMake($replregex,0);
      $sendregex = RcptRegexMake($sendregex,1);
    }
    next if($type ne 'S' && $type ne '' && $type ne 'R');
    @new = RecRep($toregex,$replregex,$sendregex,$recpt,$sender,$k);
    my $match;
    ($new,$match) = (shift(@new),pop(@new));
    my ($sm,$em) = $match ? ('<span class="positive">','</span>') : (undef,undef);
    push (@ret, "$sm$k $v$em");
    if ($type eq 'S' || $type eq '') {push (@ret,"$sm$k  :R\<=\>$toregex\<=\>$replregex\<=\>$sendregex\<=\>$nextrule\<=\>$jump : regex $k$em");}
    push (@ret, "$sm$k - rule result <b>$new</b>$em") if $match;

    if ($match == 1 && $nextrule == 1) {       # match and action if
      if ($jump) {
        if (! exists $$RecRepRegex{$jump}) {
          if ($jump eq 'END') {
             push (@ret, "$k jumptarget: rule $jump - found in rule $k - end processing");
          } else {
             push (@ret, "$k jumptarget: rule $jump - not found in rule $k - end processing");
          }
          last;
        }
        if ($jump eq $k) {
          push (@ret, "$k jumptarget: jump to the same rule $jump is not permitted - end processing");
          last;
        }
        if ($jump lt $k) {
          push (@ret, "$k jumptarget: jump backward from rule $k to rule $jump is not permitted - end processing");
          last;
        }
        $jmptarget = $jump;
        push (@ret, "$k jump: to rule $jump");
        next;
      }
      last;
    }

    if ($match == 0 && $nextrule == 2) {     # no match and action if
      if ($jump) {
        $recpt = $new;
        if (! exists $$RecRepRegex{$jump}) {
          if ($jump eq 'END') {
             push (@ret, "$k jumptarget: rule $jump - found in rule $k - end processing");
          } else {
             push (@ret, "$k jumptarget: rule $jump - not found in rule $k - end processing");
          }
          last;
        }
        if ($jump eq $k) {
          push (@ret, "$k jumptarget: jump to the same rule $jump is not permitted - end processing");
          last;
        }
        if ($jump lt $k) {
          push (@ret, "$k jumptarget: jump backward from rule $k to rule $jump is not permitted - end processing");
          last;
        }
        $jmptarget = $jump;
        push (@ret, "$k jump: to rule $jump");
        next;
      }
      last;
    }

    if ($nextrule == 0 && $jump) {
       $jmptarget = $jump;
       push (@ret, "$k jump: to rule $jump");
    }

    $recpt = $new;
  }
  if ($k) {
    push (@ret, "<br />returns: <b>$new</b> after rule $k in configuration");
  } else {
    push (@ret, "<br />returns: <b>$new</b> - no rule found in configuration");
  }
  if (wantarray) {
    $ret[0] = $new;
    return @ret;
  } else {
    return $new;
  }
}
