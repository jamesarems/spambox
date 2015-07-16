#line 1 "sub main::localvrfy2MTA_Run"
package main; sub localvrfy2MTA_Run {
  my ($fh,$h) = @_;
  d("localvrfy2MTA - $h") if $WorkerNumber != 10001;
  my $this;
  $this = $Con{$fh} if $fh;
  my $smtp;
  my $vrfy;
  my $expn;
  my $domain;
  my $forceRCPTTO;
  my $canvrfy;
  my $canexpn;

  $h = &batv_remove_tag(0,lc($h),'');

  return 1 if &LDAPCacheFind($h,'VRFY');
  if (my $nf = $LDAPNotFound{$h}) {
      if ((time - $nf) < 300) {
          mlog($fh,"info: found $h in LDAPNotFound - skip VRFY") if ($VRFYLog >= 2 && $WorkerNumber != 10001);
          return 0;
      } elsif (defined $nf) {
          mlog($fh,"info: found $h in LDAPNotFound - entry is too old and is removed - will force VRFY") if ($VRFYLog >= 2 && $WorkerNumber != 10001);
          delete $LDAPNotFound{$h};
      }
  }

  $domain = $1 if $h=~/\@([^@]*)/o;
  return 0 unless $domain;

  my $MTAList = &matchHashKey('DomainVRFYMTA',$domain);
  $MTAList = &matchHashKey('FlatVRFYMTA',"\@$domain") unless $MTAList;
  return 0 unless $MTAList;

  my $timeout = $VRFYQueryTimeOut ? $VRFYQueryTimeOut : 5;
  &sigoffTry(__LINE__);
  eval{
    for my $MTA (split(/,/,$MTAList)) {
      mlog($fh,"info: starting VRFY for $h on $MTA") if ($VRFYLog >= 2 && $WorkerNumber != 10001);
      eval{
      $smtp = Net::SMTP->new($MTA,
                        Hello => $myName,
                        Timeout => $timeout),
                        getLocalAddress('SMTP',$MTA);
      };
      if (! $smtp) {
          mlog($fh,"warning: unable to connect to MTA $MTA - $@") if ($VRFYLog && $WorkerNumber != 10001);
          next;
      } else {
          $forceRCPTTO = ($VRFYforceRCPTTO && $MTA =~ /$VFRTRE/) ? 1 : 0;
          mlog($fh,"info: established SMTP to $MTA - force RCPTO is '$forceRCPTTO'") if ($VRFYLog >= 2 && $WorkerNumber != 10001);
          if (! $forceRCPTTO) {
              $canvrfy = exists ${*$smtp}{'net_smtp_esmtp'}->{'VRFY'};   # was VRFY in EHLO Answer?
              $canexpn = exists ${*$smtp}{'net_smtp_esmtp'}->{'EXPN'};   # was EXPN in EHLO Answer?
              if (! $canvrfy && ! $canexpn &&   # there was no VRFY or EXPN in the EHLO Answer, or HELO was used
                  (exists ${*$smtp}{'net_smtp_esmtp'}->{'HELP'} ||    # we can use HELP      or
                   ! exists ${*$smtp}{'net_smtp_esmtp'}) )            # only HELO was used - try HELP
              {
                      my $help = $smtp->help();
                      $canvrfy = $help =~ /VRFY/io;
                      $canexpn = $help =~ /EXPN/io;
              }
              if ($canvrfy) {$vrfy = $smtp->verify($h) ? 1 : $smtp->verify("\"$h\"");}
              if ($canexpn && ! $vrfy) {$expn = scalar($smtp->expand($h)) ? 1 : scalar($smtp->expand("\"$h\""));}
          } else {
              mlog($fh,"info: using RCPT TO: (skiped VRFY) for $h") if ($VRFYLog >= 2 && $WorkerNumber != 10001);
          }
          if (!$canvrfy && !$canexpn) {    # VRFY and EXPN are both not supported or VRFYforceRCPTTO is set for this MTA
              mlog($fh,"info: host $MTA does not support VRFY and EXPN (tried EHLO and HELP) - now using RCPT TO to verify $h") if ($VRFYLog >= 2 && ! $forceRCPTTO && $WorkerNumber != 10001);
              if ($smtp->mail('postmaster@'.$myName)) {
                  $vrfy = $smtp->to($h);
              } else {
                  mlog($fh,"info: host $MTA does not accept 'mail from:postmaster\@$myName'") if $VRFYLog && $WorkerNumber != 10001;
              }
          }
          $smtp->quit;
      }
      last if ($vrfy || $expn);
    }
  };
  if ($@ || ! $smtp) {
     $vrfy = 0 ;
     $expn = 0 ;
     my $not =  $LDAPFail ? ' not' : '';
     if ($@){
         mlog($fh,"error: VRFY / RCPT TO failed on host $MTAList - address <$h>$not accepted - $@") if $WorkerNumber != 10001;
     } else {
         mlog($fh,"error: VRFY / RCPT TO failed on host $MTAList - address <$h>$not accepted") if $WorkerNumber != 10001;
     }
     &sigonTry(__LINE__);
     $this->{userTempFail} = ! $LDAPFail if $this;
     return ! $LDAPFail;
  }
  &sigonTry(__LINE__);
  delete $this->{userTempFail} if $this;
  if ($vrfy || $expn) {
     if ($ldaplistdb) {
         $LDAPlist{$h}=time." 1";
         mlog($fh,"VRFY added $h to VRFY-/LDAPlist") if $VRFYLog && $WorkerNumber != 10001;
         d("VRFY added $h to LDAP-cache",1) if $WorkerNumber != 10001;
     }
     delete $LDAPNotFound{$h};
     mlog($fh,"info: VRFY found $h") if $VRFYLog >= 2 && $WorkerNumber != 10001;
     return 1 ;
  } else {
     $LDAPNotFound{$h} = time;
     mlog($fh,"info: caching result for $h in LDAPNotFound") if $VRFYLog > 1;
  }
  mlog($fh,"info: VRFY was unable to find $h") if $VRFYLog >= 2 && $WorkerNumber != 10001;
  return 0;
}
