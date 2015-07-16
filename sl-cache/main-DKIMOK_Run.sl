#line 1 "sub main::DKIMOK_Run"
package main; sub DKIMOK_Run {
  my($fh,$message,$doBody)=@_;          # returns:
  my $this=$Con{$fh};                   #  0 = DKIM is failed -> this is SPAM
  d('DKIMOK');                          #  1 = no DKIM - check
  my $tlit;                             #  2 = DKIM check is OK (pass) -> do not modify the mail
  my $result;
  $fh = 0 if "$fh" =~ /^\d+$/o;
  my $retval = 1;
  my $dkim;
  my $ip = $this->{ip};
  $ip = $this->{cip} if $this->{ispip} && $this->{cip};
  $retval = 2 if ($this->{isDKIM});   # this is DKIM -> do not modify
  return $retval if (! $DoStrictDKIM && $this->{dkimverified});
  return $retval if ($this->{dkimresult} && $this->{dkimresult} ne 'pass');
  $this->{dkimverified} = "not verified";
  return $retval if !$CanUseDKIM;
  return $retval if $this->{invalidSenderDomain};
  skipCheck($this,'wl','np','ro','rw','co','nodkim','MSGIDsigRemoved') && return $retval;
  return 1 if $this->{isbounce};
  return $retval if (&matchSL($this->{mailfrom},'noDKIMAddresses'));
  return $retval if &matchIP($ip,'noDKIMIP',$fh,0);

  $tlit = &tlit($DoDKIM);
  $this->{prepend}='';
  my $detail;
  my $dkimpolicy_a;
  my $dkimwhy_a;
  my $dkimpolicy_s;
  my $dkimwhy_s;

  &sigoff(__LINE__);
  eval { $Mail::DKIM::DNS::RESOLVER = getDNSResolver(); };
  $dkim = Mail::DKIM::Verifier->new();
  eval {
      for my $msgLine (split(/\n/o, $$message))
      {
          $msgLine =~ s/^\.([^\015]+\015)$/$1/o;
          $dkim->PRINT("$msgLine\n") if ($msgLine !~ /^\.[\015]?$/o);
      }
      $dkim->CLOSE;
      $this->{dkimresult} = $result = $dkim->result;
      $detail = $dkim->result_detail;
      $dkimpolicy_a  = $dkim->fetch_author_policy;
      $dkimwhy_a     = $dkimpolicy_a->apply($dkim);
      $dkimpolicy_s  = $dkim->fetch_sender_policy;
      $dkimwhy_s     = $dkimpolicy_s->apply($dkim);
  };
  my $except = $@;
  &sigon(__LINE__);
  $this->{dkimverified} = "verified-OK";
  if ($except) {
      $this->{dkimverified} = $result = $except;
      mlog($fh,"warning: DKIM returned '$except'");
      return $retval;
  }

  if ( ($detail =~ /fail.+?(?:body|message).+?altered/io)    &&
       ($dkimwhy_a eq "neutral" || $dkimwhy_a eq "accept") &&
       ($dkimwhy_s eq "neutral" || $dkimwhy_s eq "accept") &&
       (! $DoStrictDKIM || ! $doBody)) {
       $this->{dkimresult} = $result = "pass";
       $this->{dkimverified} = "body altered - header passed - suspicious-OK";
       if (! $doBody) {
           $this->{dkimverified} = "verified-OK";
           $detail = 'header-passed';
       }
  }

  if ($this->{myheader} =~ s/X-Original-Authentication-Results:($HeaderValueRe)//ois) {
      my $val = $1;
      headerUnwrap($val);
      $val =~ s/\r|\n//go;
      $val =~ s/ dkim=\S+//o;
      $val .= " dkim=$result";
      $this->{myheader} .= "X-Original-Authentication-Results:$val\r\n";
  } else {
      $this->{myheader} .= "X-Original-Authentication-Results: $myName; dkim=$result\r\n";
  }
  
  if (($result eq "fail" || ($result eq "none" && $this->{isDKIM})) && ! $dkimpolicy_a->testing) {
    $this->{prepend}="[DKIM]";
    mlog($fh,"$tlit DKIM signature failed - $detail - sender policy is: $dkimwhy_s - author policy is: $dkimwhy_a") if $ValidateSenderLog && $DoDKIM==3 || $DoDKIM==2;
    pbWhiteDelete($fh,$this->{ip});
    $this->{dkimverified} = "failed";
    return $retval if $DoDKIM==2;
    $this->{messagereason}="DKIM $result";
    pbAdd($fh,$this->{ip},'dkimValencePB','DKIMfailed');
    delayWhiteExpire($fh);
    return $retval if $DoDKIM==3;
    return 0;
  }
  if ($result eq "pass") {
    mlog($fh,"$tlit DKIM signature $this->{dkimverified} - $detail - sender policy is: $dkimwhy_s - author policy is: $dkimwhy_a") if $ValidateSenderLog && $DoDKIM>=2;
    $this->{rwlok}=1;
    $this->{messagereason}="DKIM $result";
    pbAdd($fh,$this->{ip},'dkimOkValencePB','DKIMpass', 1);
    my $mf =lc $this->{mailfrom};
    my $domain;
    $domain = $1 if $mf=~/\@([^@]*)/o;
    DKIMCacheAdd($domain);     # DKIM is pass => all further mails should have a DKIM-Sig
    if ( $fh && ! $this->{relayok} ) {      # clear the IP-PBBOX in case DKIM is OK
        $this->{nopb} = 1;
        mlog($fh,"info: remove IP-score from $this->{ip} - this mail passed the DKIM check") if ($SessionLog || $ValidateSenderLog) && exists $PBBlack{$this->{ip}};
        mlog($fh,"info: remove IP-score from $this->{cip} - this mail passed the DKIM check") if ($SessionLog || $ValidateSenderLog) && $this->{cip} && exists $PBBlack{$this->{cip}};
        pbBlackDelete($fh, $this->{ip});
    }
    return 2;
  }

  if ($result eq "none") {
    mlog($fh,"$tlit (DKIM signature not found)") if $ValidateSenderLog && $DoDKIM>=2;
    $this->{dkimverified} = "no-signature";
    return 1;
  }

  if ($result eq "invalid") {
    mlog($fh,"$tlit (DKIM signature invalid) - " . $dkim->{signature_reject_reason} ) if $ValidateSenderLog && $DoDKIM>=2;
    $this->{dkimverified} = "invalid-signature";
    return $retval;
  }
  if ($dkimpolicy_a->testing) {
    mlog($fh,"$tlit DKIM signature failed - but DKIM test policy - $detail - sender policy is: $dkimwhy_s - author policy is: $dkimwhy_a") if $ValidateSenderLog && $DoDKIM==3 || $DoDKIM==2;
  }
  return $retval;
}
