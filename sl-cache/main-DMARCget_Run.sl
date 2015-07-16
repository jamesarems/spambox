#line 1 "sub main::DMARCget_Run"
package main; sub DMARCget_Run {
   my $fh = shift;
   d('DMARCget');
   return unless $ValidateSPF && $DoDKIM && $DoDMARC;
   my $this = $Con{$fh};
   $fh = 0 if "$fh" =~ /^\d+$/o;
   skipCheck($this,'aa','ro','np','invalidSenderDomain') && return;
   my $mfd;
   $mfd = $1 if $this->{mailfrom} =~ /\@($EmailDomainRe)/o;
   my $toDomain;
   $toDomain = $1 if $this->{orgrcpt} =~ /\@($EmailDomainRe)/o;
   $toDomain = $1 if (! $toDomain && $this->{rcpt} =~ /\@($EmailDomainRe)/o);
   return unless $toDomain;
   my ($domain , $mf);
   $mf = $1 if $this->{header} =~ /(?:^|\n)from:($HeaderValueRe)/ios;
   return unless $mf;
   headerUnwrap($mf);
   $domain = $1 if $mf=~/\@($EmailDomainRe)/o;
   return if localdomains($domain);
   return if (! $domain);
   my $ip = $this->{ip};
   $ip = $this->{cip} if $this->{ispip} && $this->{cip};
   my @domains = split(/\./o,$domain);
   my $topdom;
   mlog(0,"info: try DMARC") if $SPFLog >= 2;
   my @lookupdomain = map {$topdom = $_ .($topdom?'.':'').$topdom;$topdom;} reverse @domains;

   shift @lookupdomain; # remove the TLD
   do {
       $topdom = pop @lookupdomain;
       delete $this->{dmarc};
       my $qdmarc = '_dmarc.'. $topdom;
       mlog(0,"info: looking for DMARC in $qdmarc") if $SPFLog >= 2;
       my $dns = lc( getRRData($qdmarc,(defined *{'yield'}?'TXT':'A')) );
       $dns =~ s/[ '";\\]+$//o;
       mlog(0,"info: got RR $qdmarc - $dns") if $SPFLog >= 2;
       $this->{dmarc} = {map {$_ =~ s/[ '"\\]//gio;$_} map{split(/=/o,$_,2)} split(/[; ]+/o,$dns)};   ## no critic
   } while (@lookupdomain && $this->{dmarc}->{v} ne 'dmarc1');

   if ($SPFLog >= 2) {
        foreach (keys %{$this->{dmarc}}) {
            mlog(0,"info: got DMARC $_ = $this->{dmarc}->{$_}");
        }
   }
   $this->{dmarc}->{pct} ||= 100;
   if (   $this->{dmarc}->{v} ne 'dmarc1'
       || ! exists $this->{dmarc}->{p}
       || rand(100) > $this->{dmarc}->{pct})
   {
       delete $this->{dmarc};
       return;
   }

   while ($this->{header} =~ /X-Original-Authentication-Results:($HeaderValueRe)/gios) {
       my $h = $1;
       headerUnwrap($h);
       $this->{dmarc}->{auth_results}->{spf} = $1 if $h =~ /spf=([\s\r\n;]+)/io;
       $this->{dmarc}->{auth_results}->{dkim} = $1 if $h =~ /dkim=([\s\r\n;]+)/io;
       $this->{dmarc}->{policy_evaluated}->{reason} = 'trusted_forwarder';
   }
   if (! $this->{dmarc}->{auth_results}->{spf} && ! $this->{dmarc}->{auth_results}->{dkim}) {
       while ($this->{header} =~ /X-Spam-Report:($HeaderValueRe)/gios) {    # SF workaround
           my $h = $1;
           headerUnwrap($h);
           next if $h !~ /mx\.sourceforge\.net/o;
           $this->{dmarc}->{auth_results}->{spf} = ($h =~ /SPF_PASS/io) ? 'pass' : 'fail';
           $this->{dmarc}->{auth_results}->{dkim} = ($h =~ /DKIM_VALID_AU/io) ? 'pass' : 'fail';
           $this->{dmarc}->{policy_evaluated}->{reason} = 'mailing_list';
       }
   }

   mlog($fh,"info: domain $topdom has published a DMARC record") if $SessionLog || $SPFLog;
   $this->{dmarc}->{domain} = $topdom;
   $this->{dmarc}->{dom} = $domain;
   $this->{dmarc}->{toDomain} = $toDomain;
   $this->{dmarc}->{mfd} = $mfd;
   my @dkimDom;
   if ($this->{isDKIM}) {
       if ($this->{dkimresult}) {
           if (! $this->{dmarc}->{auth_results}->{dkim}) {
               $this->{dmarc}->{auth_results}->{dkim} = $this->{dkimresult} ;
           }
       }
       while ($this->{header} =~ /DKIM-Signature:($HeaderValueRe)/gios) {
           my $h = $1;
           headerUnwrap($h);
           push @dkimDom , lc($1) if $h =~ /[; ]+d=([^;]+);/io;
       }
   }
   @{$this->{dmarc}->{DKIMdomains}} = @dkimDom if @dkimDom;
   $this->{dmarc}->{sp} ||= $this->{dmarc}->{p};
   $this->{dmarc}->{aspf} ||= 'r';
   $this->{dmarc}->{adkim} ||= 'r';
   $this->{dmarc}->{rf} ||= 'afrf';
   $this->{dmarc}->{ri} ||= 86400;
   $this->{dmarc}->{fo} ||= 0;
   $this->{dmarc}->{source_ip} = $ip;
   if (! $DMARCReportFrom) {
       delete $this->{dmarc}->{rua};
       delete $this->{dmarc}->{ruf};
       delete $this->{dmarc}->{fo};
       return;
   }
   delete $this->{dmarc}->{rua} if $this->{dmarc}->{rua} !~ s/mailto://oig;
   delete $this->{dmarc}->{ruf} if $this->{dmarc}->{ruf} !~ s/mailto://oig;
   my ($rufDom,$rufSize);
   my ($ruaDom,$ruaSize);
   ($rufDom,$rufSize) = ($1,$2) if $this->{dmarc}->{ruf} =~ /\@($EmailDomainRe)(?:!(\d+[kmg]?))?/oi;
   ($ruaDom,$ruaSize) = ($1,$2) if $this->{dmarc}->{rua} =~ /\@($EmailDomainRe)(?:!(\d+[kmg]?))?/oi;
   delete $this->{dmarc}->{ruf} unless $rufDom;
   delete $this->{dmarc}->{rua} unless $ruaDom;
   $this->{dmarc}->{rufSize} = unformatDataSize($rufSize.'b') if $rufSize && $this->{dmarc}->{ruf};
   $this->{dmarc}->{ruaSize} = unformatDataSize($ruaSize.'b') if $ruaSize && $this->{dmarc}->{rua};
   delete $this->{dmarc}->{fo} unless exists $this->{dmarc}->{ruf};
   my $skipruf = ($rufDom ne '' && $ruaDom ne '' && $ruaDom eq $rufDom);
   if ($ruaDom && $ruaDom ne $topdom) {
        my $rec = $topdom.'._report._dmarc.'.$ruaDom;
        my $rDMARC = {map {$_ =~ s/[ '"\\]//gio;$_} map{split(/=/o,$_,2)} split(/[; ]+/o,lc( getRRData($rec,(defined *{'yield'}?'TXT':'A'))))}; ## no critic
        if ($rDMARC->{v} eq 'dmarc1') {
            if ($rDMARC->{rua}) {
                delete $this->{dmarc}->{ruaSize};
                delete $this->{dmarc}->{rua};
                $rDMARC->{rua} =~ s/ //og;
                $this->{dmarc}->{rua} = $rDMARC->{rua};
                my ($rruaDom,$rruaSize);
                ($rruaDom,$rruaSize) = ($1,$2) if $this->{dmarc}->{rua} =~ /\@($EmailDomainRe)(?:!(\d+[kmg]?))?/oi;
                delete $this->{dmarc}->{rua} if (! $rruaDom || $rruaDom !~ /^(?:\*\.?)?\Q$ruaDom\E/i);
                delete $this->{dmarc}->{rua} if $this->{dmarc}->{rua} !~ s/mailto://oig;
                $this->{dmarc}->{ruaSize} = unformatDataSize($rruaSize.'b') if $rruaSize && exists $this->{dmarc}->{rua};
                $skipruf = 0 if exists $this->{dmarc}->{rua};
            }
        } else {
            $rec = '*._report._dmarc.'.$ruaDom;
            $rDMARC = {map {$_ =~ s/[ '"\\]//gio;$_} map{split(/=/o,$_,2)} split(/[; ]+/o,lc( getRRData($rec,(defined *{'yield'}?'TXT':'A'))))}; ## no critic
            if ($rDMARC->{v} ne 'dmarc1') {
                delete $this->{dmarc}->{ruaSize};
                delete $this->{dmarc}->{rua};
                $skipruf = 1;
            }
        }
   }
   if ($skipruf) {
       $this->{dmarc}->{ruf} = $this->{dmarc}->{rua};
       delete $this->{dmarc}->{fo} unless exists $this->{dmarc}->{ruf};
       return;
   }
   if ($rufDom && $rufDom ne $topdom) {
        my $rec = $topdom.'._report._dmarc.'.$rufDom;
        my $rDMARC = {map {$_ =~ s/[ '"\\]//gio;$_} map{split(/=/o,$_,2)} split(/[; ]+/o,lc( getRRData($rec,(defined *{'yield'}?'TXT':'A'))))}; ## no critic
        if ($rDMARC->{v} eq 'dmarc1') {
            if ($rDMARC->{ruf}) {
                delete $this->{dmarc}->{rufSize};
                delete $this->{dmarc}->{ruf};
                $rDMARC->{ruf} =~ s/ //og;
                $this->{dmarc}->{ruf} = $rDMARC->{ruf};
                my ($rrufDom,$rrufSize);
                ($rrufDom,$rrufSize) = ($1,$2) if $this->{dmarc}->{ruf} =~ /\@($EmailDomainRe)(?:!(\d+[kmg]?))?/oi;
                delete $this->{dmarc}->{ruf} if (! $rrufDom || $rrufDom !~ /^(?:\*\.?)?\Q$rufDom\E/i);
                delete $this->{dmarc}->{ruf} if $this->{dmarc}->{ruf} !~ s/mailto://oig;
                $this->{dmarc}->{rufSize} = unformatDataSize($rrufSize.'b') if $rrufSize && exists $this->{dmarc}->{ruf};
            }
        } else {
            $rec = '*._report._dmarc.'.$rufDom;
            $rDMARC = {map {$_ =~ s/[ '"\\]//gio;$_} map{split(/=/o,$_,2)} split(/[; ]+/o,lc( getRRData($rec,(defined *{'yield'}?'TXT':'A'))))}; ## no critic
            if ($rDMARC->{v} ne 'dmarc1') {
                delete $this->{dmarc}->{rufSize};
                delete $this->{dmarc}->{ruf};
            }
        }
   }
   delete $this->{dmarc}->{fo} unless exists $this->{dmarc}->{ruf};
   return;
}
