#line 1 "sub main::DMARCok"
package main; sub DMARCok {
   my $fh = shift;
   d('DMARCok');
   my $this = $Con{$fh};
   $fh = 0 if "$fh" =~ /^\d+$/o;
   return 1 if $this->{DMARCokDone};
   $this->{DMARCokDone} = 1;
   return 1 unless $this->{dmarc};
   return 1 unless $this->{spf_result};
   skipCheck($this,'aa','ro','co') && return 1;
   my $failed;
   $failed = $this->{dmarc}->{auth_results} if $this->{dmarc}->{auth_results};
   
   $failed->{spf} ||= $this->{spf_result} if $this->{dmarc}->{aspf} eq 's' && $this->{spf_result} ne 'pass';
   $failed->{spf} ||= $this->{spf_result} if $this->{dmarc}->{aspf} eq 'r' && $this->{spf_result} !~ /pass|softfail|neutral/o;

   if (@{$this->{dmarc}->{DKIMdomains}}) {
       $failed->{dkim} ||= 'fail' if $this->{dmarc}->{adkim} eq 's' && ! grep(/^\Q$this->{dmarc}->{dom}\E$/,@{$this->{dmarc}->{DKIMdomains}});
       $failed->{dkim} ||= 'fail' if $this->{dmarc}->{adkim} eq 'r' && ! grep(/\Q$this->{dmarc}->{domain}\E$/,@{$this->{dmarc}->{DKIMdomains}});
       mlog($fh,"DMARC: this mail breakes the DKIM rules defined in the DMARC record for domain $this->{dmarc}->{dom} - 'adkim'=$this->{dmarc}->{adkim} check result='$failed->{dkim}'") if $SPFLog && $failed->{dkim} eq 'fail';
   } else {
       $failed->{dkim} ||= 'fail' if $this->{dmarc}->{adkim} eq 's';
       $failed->{dkim} ||= 'neutral' if $this->{dmarc}->{adkim} eq 'r';
       mlog($fh,"DMARC: this mail breakes the DKIM policies defined in the DMARC record for domain $this->{dmarc}->{domain} - there is no DKIM-signature found in this mail for domain $this->{dmarc}->{domain}") if $SPFLog;
   }
   DKIMCacheAdd($this->{dmarc}->{domain}) if $this->{dmarc}->{domain} ne $this->{dmarc}->{dom};
   DKIMCacheAdd($this->{dmarc}->{dom});
   $failed->{spf} ||= 'pass';
   $failed->{dkim} ||= 'pass';
   $this->{dmarc}->{auth_results} = $failed;
   $this->{dmarc}->{policy_evaluated}->{dkim} = $this->{dmarc}->{auth_results}->{dkim};
   $this->{dmarc}->{policy_evaluated}->{spf} = $this->{dmarc}->{auth_results}->{spf};
   $this->{dmarc}->{policy_evaluated}->{dkim} = 'fail' if $this->{dmarc}->{policy_evaluated}->{dkim} ne 'pass';
   $this->{dmarc}->{policy_evaluated}->{spf} =  'fail' if $this->{dmarc}->{policy_evaluated}->{spf} ne 'pass';

   DMARCaddReport($fh) if $fh && $this->{dmarc}->{rf} eq 'afrf' && $this->{dmarc}->{rua} && ! matchSL($this->{dmarc}->{rua},'noDMARCReportDomain');

   return 1 if ($failed->{spf} eq 'pass' && $failed->{dkim} eq 'pass');

   my %fo;
   $fo{$_} = 1 for split(/\s*[:,]\s*/o,lc $this->{dmarc}->{fo});
   delete $fo{1} unless ($failed->{spf} eq 'fail' && $failed->{dkim} eq 'fail');
   delete $fo{0} unless ($failed->{spf} eq 'fail' || $failed->{dkim} eq 'fail');
   delete $fo{d} unless ($failed->{dkim} eq 'fail');
   delete $fo{s} unless ($failed->{spf} eq 'fail');

   DMARCSendForensic($fh) if (   $fh
                              && scalar keys %fo
                              && $this->{dmarc}->{ruf}
                              && ! matchSL($this->{dmarc}->{ruf},'noDMARCReportDomain')
                              && (    ($this->{dmarc}->{domain} eq $this->{dmarc}->{dom} && $this->{dmarc}->{p} =~ /reject|quarantine/io)
                                   || ($this->{dmarc}->{domain} ne $this->{dmarc}->{dom} && $this->{dmarc}->{sp} =~ /reject|quarantine/io)
                                 )
                              && (    ($this->{dmarc}->{adkim} eq 's' && $this->{dmarc}->{policy_evaluated}->{dkim} eq 'fail')
                                   || ($this->{dmarc}->{aspf}  eq 's' && $this->{dmarc}->{policy_evaluated}->{spf}  eq 'fail')
                                 )
                             );

   return 1 if $this->{dmarc}->{domain} eq $this->{dmarc}->{dom} && $this->{dmarc}->{p} eq 'none';
   return 1 if $this->{dmarc}->{domain} ne $this->{dmarc}->{dom} && $this->{dmarc}->{sp} eq 'none';

   my $validate = $DoDKIM;
   $validate = 2 if $ValidateSPF == 2;
   $validate = 3 if ($validate != 2 && $ValidateSPF == 3);

   my $tlit = tlit($validate);
   return 1 if $validate == 3;
   $this->{messagereason} = "DMARC failed";
   mlog( $fh, "$tlit $this->{messagereason} SPF:$failed->{spf} DKIM:$failed->{dkim}") if $SPFLog;
   $this->{myheader} .= "X-Assp-DMARC-failed: SPF:$failed->{spf} DKIM:$failed->{dkim}\r\n";
   pbAdd( $fh, $this->{dmarc}->{source_ip}, 'spfValencePB', "DMARC-failed" );
   return 1 if $validate == 2;
   return 1 if $this->{dmarc}->{domain} eq $this->{dmarc}->{dom} && $this->{dmarc}->{p} !~ /reject|quarantine/io;
   return 1 if $this->{dmarc}->{domain} ne $this->{dmarc}->{dom} && $this->{dmarc}->{sp} !~ /reject|quarantine/io;
   my $reply = $SPFError;
   $reply =~ s/SPFRESULT/DMARC-failed/go;
   my $slok = $this->{allLoveSPFSpam} == 1;

   $Stats{spffails}++ if $slok && $fh;

   $this->{prepend} = '[DMARC]';
   thisIsSpam( $fh, "DMARC failed", $SPFFailLog, $reply, $this->{testmode}, $slok, 0 );
   return 0;
}
