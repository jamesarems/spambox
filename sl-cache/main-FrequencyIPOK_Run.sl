#line 1 "sub main::FrequencyIPOK_Run"
package main; sub FrequencyIPOK_Run {
    my $fh = shift;
    d('FrequencyIPOK');
    my $this = $Con{$fh};
    skipCheck($this,'wl','np','co') && return 1;

    my $ConIp550 = $this->{ip};
    if ($this->{ispip} && $this->{cip}) {
        $ConIp550 = $this->{cip};
    } elsif ($this->{ispip} && ! @{$this->{sip}}) {
        return 1;
    } elsif ($this->{ispip}) {
        $ConIp550 = undef;
    }
    my @noips = split(/\s+/o,$this->{doneDoFrequencyIP});
    my @ipsToCheck;
    foreach my $ip (@{$this->{sip}},$ConIp550) {
        next unless $ip;
        next if grep {$ip eq $_} @noips;
        push @ipsToCheck, $ip;
    }
    
    $this->{doneDoFrequencyIP} = join(' ', @noips, @ipsToCheck);
    return 1 unless @ipsToCheck;

    while (my $ConIp550 = shift @ipsToCheck) {
        if (       ! matchIP( $ConIp550, 'noPB',            0, 1 )
                && ! matchIP( $ConIp550, 'noProcessingIPs', $fh, 1 )
                && ! matchIP( $ConIp550, 'whiteListedIPs',  $fh, 1 )
                && ! matchIP( $ConIp550, 'noDelay',         $fh, 1 )
                && ! matchIP( $ConIp550, 'acceptAllMail',   0, 1 )
                && ! matchIP( $ConIp550, 'noBlockingIPs',   $fh, 1 )
                &&   pbBlackFind($ConIp550)
                && ! pbWhiteFind($ConIp550)
           )
            # ip connection limiting per timeframe
        {

   # If the IP address has tried to connect previously, check it's frequency
            if ( $IPNumTries{$ConIp550} ) {
                $IPNumTries{$ConIp550}++;

          # If the last connect time is past expiration, reset the counters.
          # If it has not expired, but is outside of frequency duration and
          # below the maximum session limit, reset the counters. If it is
          # within duration
                if (((time - $IPNumTriesExpiration{$ConIp550}) > $maxSMTPipExpiration)  || ((time - $IPNumTriesDuration{$ConIp550}) > $maxSMTPipDuration) && ($IPNumTries{$ConIp550} < $maxSMTPipConnects)) {
                    $IPNumTries{$ConIp550} = 1;
                    $IPNumTriesDuration{$ConIp550} = time;
                    $IPNumTriesExpiration{$ConIp550} = time;
                }
            } else {
                $IPNumTries{$ConIp550} = 1;
                $IPNumTriesDuration{$ConIp550} = time;
                $IPNumTriesExpiration{$ConIp550} = time;

            }
            my $tlit = &tlit($DoFrequencyIP);
            $tlit = '[testmode]'   if $allTestMode && $DoFrequencyIP == 1 || $DoFrequencyIP == 4;

            my $DoFrequencyIP = $DoFrequencyIP;
            $DoFrequencyIP = 3 if $allTestMode && $DoFrequencyIP == 1 || $DoFrequencyIP == 4;

            if ( $IPNumTries{$ConIp550} > $maxSMTPipConnects ) {
                $this->{prepend} = '[IPfrequency]';
                my $whatip = ($ConIp550 eq $this->{ip}) ? '' : 'originated IP ';
                $this->{messagereason} = "$whatip'$ConIp550' passed limit($maxSMTPipConnects) of ip connection frequency";

                mlog( $fh, "$tlit $this->{messagereason}")
                  if $SessionLog >= 2
                      && $IPNumTries{$ConIp550} > $maxSMTPipConnects + 1;
                mlog( $fh,"$tlit $this->{messagereason}")
                  if $SessionLog
                      && $IPNumTries{$ConIp550} == $maxSMTPipConnects + 1;
                pbAdd( $fh, $ConIp550, 'ifValencePB', 'IPfrequency' ) if $DoFrequencyIP!=2;
                if ( $DoFrequencyIP == 1 ) {
                    $Stats{smtpConnLimitFreq}++;
                    unless (($send250OKISP && $this->{ispip}) || $send250OK) {
                        if ($ConIp550 eq $this->{ip}) {
                            seterror( $fh, "554 5.7.1 too frequent connections for '$ConIp550'", 1 );
                        } else {
                            seterror( $fh, "554 5.7.1 too frequent connections for originated IP-address '$ConIp550'", 1 );
                        }
                        return 0;
                    }
                }
            }
        }
    }
    return 1;
}
