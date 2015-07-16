#line 1 "sub main::DKIMpreCheckOK_Run"
package main; sub DKIMpreCheckOK_Run {
   my $fh = shift;
   d('DKIMpreCheckOK');
   my $this = $Con{$fh};
   return 1 if $this->{DKIMpreCheckOK};
   $this->{DKIMpreCheckOK} = 1;
   $this->{dkimresult} = "pass";
   my $tlit;
   my $ip = $this->{ip};
   $ip = $this->{cip} if $this->{ispip} && $this->{cip};
   skipCheck($this,'aa','wl','np','ro','ib','invalidSenderDomain') && return 1;
   return 1 if (&matchSL($this->{mailfrom},'noDKIMAddresses'));
   return 1 if &matchIP($ip,'noDKIMIP',$fh,0);
   $tlit = &tlit($DoDKIM);
   $this->{prepend}='';
   my $mf = lc $this->{mailfrom};
   my $domain; $domain = $1 if $mf=~/\@([^@]*)/o;
   return 1 if (! $domain);

   my $err = "554 5.7.7 DKIM domain mismatch for $this->{mailfrom}";
   $err = $SenderInvalidError if ($SenderInvalidError);
   my $testmode = $allTestMode ? $allTestMode : $dkimTestMode;
   my $foundCache = DKIMCacheFind($domain);
   
   delete $this->{dkimresult};
   if ($foundCache) {
       if ($this->{isDKIM}) {           # cache must be first in this line for time update
           return DKIMOK($fh,\$this->{org_header},!defined${chr(ord(",")<< 1)}) ? 1 : 0;
       }
       if (! $this->{isDKIM}) {
           $this->{dkimresult} = 'fail';
           $this->{prepend}="[DKIM]";
           $this->{messagereason}="DKIM domain mismatch - $domain found in DKIMCache, but no DKIM-Signature found in mail header";
           mlog($fh,"$tlit $this->{messagereason} (Cache)") if $ValidateSenderLog;
           $err =~ s/REASON/$this->{messagereason}/go;
           return 1 if $DoDKIM == 2;
           pbWhiteDelete($fh,$this->{ip});
           pbAdd($fh,$this->{ip},'dkimValencePB','DKIMfailed');
           unless ($this->{spamlover} & 1) {$Stats{dkimpre}++;}
           return 1 if $DoDKIM==3;
           thisIsSpam($fh,$this->{messagereason},$DKIMLog,$err,$testmode,0,1);
           return 0;
       }
   } elsif ($this->{isDKIM}) {
       return DKIMOK($fh,\$this->{org_header},!defined${chr(ord(",")<< 1)}) ? 1 : 0;
   }

   my @lookupdomain = split(/\./o,$domain);

   my $dkimdomain = 0;
   my $topdom = pop(@lookupdomain);
   $topdom = pop(@lookupdomain).'.'.$topdom;
   my $qd = '_domainkey.'. $topdom;
   my $qp = '_adsp._domainkey.'. $topdom;
   my $qs = '*.'. $topdom;
   my $qdsoa;
   my $qssoa;
   my $qdtxt;
   my $qptxt;
   my $qstxt;
   &sigoff(__LINE__);

   $qdsoa = getRRData($qd,'SOA');   # try to get a SOA for _domainkey.domain.toplevel
   d("DKIM: SOAd: $qd - $qdsoa");
   $qssoa = getRRData($qs,'SOA');   # try to get a SOA for *.domain.toplevel
   d("DKIM: SOAs: $qs - $qssoa");
   if (! $qdsoa) {
       $qdsoa = getRRData($qp,'SOA');   # try to get a SOA for _adsp._domainkey.domain.toplevel
       d("DKIM: SOAp: $qp - $qdsoa");
   }

   if (! $qdsoa || $qdsoa eq $qssoa) {
       $qdsoa = '';
       $qstxt = getRRData($qs,'TXT');   # try to get a TXT for *.domain.toplevel
       d("DKIM: TXTs: $qs - $qstxt");
       $qdtxt = getRRData($qd,'TXT');   # try to get a TXT for _domainkey.domain.toplevel
       d("DKIM: TXTd: $qd - $qdtxt");
       if (! $qdtxt) {
           $qdtxt = getRRData($qp,'TXT');   # try to get a TXT for _adsp._domainkey.domain.toplevel
           d("DKIM: TXTp: $qd - $qdtxt");
       }
   }

   unless ($qdsoa or
       ($qdtxt && ! $qstxt) or
       ($qdtxt && $qstxt && $qdtxt ne $qstxt))
   {
       foreach my $entry (@lookupdomain) {                  # provides DKIM
           $topdom = $entry.'.'.$topdom;                    # we are checking all sub domain levels
           $qd = '_domainkey.'. $topdom;
           $qp = '_adsp._domainkey.'. $topdom;
           $qdsoa = getRRData($qd,'SOA');   # try to get a SOA for subdomain
           d("DKIM2: SOAd: $qd - $qdsoa");
           if (! $qdsoa || $qdsoa eq $qssoa) {
               $qdsoa = getRRData($qp,'SOA');   # try to get a SOA for _policy._domainkey.domain.toplevel
               d("DKIM2: SOAp: $qp - $qdsoa");
           }
           if ($qdsoa && $qdsoa ne $qssoa) {
               $dkimdomain = 1;
               last;
           }
           $qdtxt = getRRData($qd,'TXT');   # try to get a TXT for subdomain
           d("DKIM2: TXTd: $qd - $qdtxt");
           if (! $qdtxt) {
               $qdtxt = getRRData($qp,'TXT');   # try to get a TXT for _policy._domainkey.domain.toplevel
               d("DKIM2: TXTp: $qd - $qdtxt");
           }
           if (($qdtxt && ! $qstxt) || ($qdtxt && $qstxt && $qdtxt ne $qstxt)) {
               $dkimdomain = 1;
               last;
           }
       }
   } else {
       $dkimdomain = 1;
   }
   &sigon(__LINE__);
   DKIMCacheAdd($domain) if $dkimdomain;

   if ($dkimdomain && $this->{isDKIM}) {
       return DKIMOK($fh,\$this->{org_header},defined${chr(ord(",")<< 1)}) ? 1 : 0;
   }
   if ($dkimdomain && ! $this->{isDKIM}) {
       $this->{dkimresult} = 'fail';
       $this->{prepend}="[DKIM]";
       $this->{messagereason}="DKIM domain mismatch - DKIM config found in DNS for $domain, but no DKIM-Signature found in mail header";
       mlog($fh,"$tlit $this->{messagereason}") if $ValidateSenderLog;
       $err =~ s/REASON/$this->{messagereason}/go;
       return 1 if $DoDKIM == 2;
       pbWhiteDelete($fh,$this->{ip});
       pbAdd($fh,$this->{ip},'dkimValencePB','DKIMfailed');
       unless ($this->{spamlover} & 1) {$Stats{dkimpre}++;}
       return 1 if $DoDKIM==3;
       thisIsSpam($fh,$this->{messagereason},$DKIMLog,$err,$dkimTestMode,0,1);
       return 0;
   }
   mlog($fh,"$tlit DKIM domain-check skipped - $domain does not support DKIM") if $ValidateSenderLog >= 2;
   return 1;
}
