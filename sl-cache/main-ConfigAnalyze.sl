#line 1 "sub main::ConfigAnalyze"
package main; sub ConfigAnalyze {
    my ( $ba, $st, $fm, %fm, %to, %wl, $ip, $helo, $text, $ip3, $received , $emfd, $mailfrom, $rcptto, $hasheader, $headTo, $org_headTo);
    my $checkRegex = ! $silent && $AnalyzeLogRegex;
    my $mail = $qs{mail};
    if (! $mail && $qs{file}) {
        my $filename = $qs{file};
        $filename = "$base/$filename" if $filename !~ /^\Q$base\E/io;
        if ( $open->(my $F, '<' , $filename) ) {
            binmode $F;
            $mail = join('',<$F>);
            close $F;
            $fm .= "<b></b><br />Analyzed file is $filename\n";
        } else {
            $fm .= "<b>ERROR: unable to open file '$filename'</b><br />\n";
        }
    }
    $mail =~ s/\r?\n/\r\n/gos;
    my $maillength = length($mail);
    my $completeMail = $mail;
    my $hasDKIM;
    if ($DoDKIM && $mail =~ /\n(?:DKIM|DomainKey)-Signature:/ois) {
        $hasDKIM = 1;
    }
    my $hl = getheaderLength(\$mail);
    $hasheader = $hl;
    my $mBytes = $MaxBytes ? $MaxBytes + $hl : 10000 + $hl;
    $mail = substr( $mail , 0, $mBytes );
    if ($qs{translit} && $CanUseTextUnidecode) {
        my $cOK;
        if ($hl) {
            ($mail,$cOK) = &clean( substr( $mail, 0, $mBytes ) );
        } else {
            $mail = decodeMimeWords2UTF8($mail);
        }
        $mail =~ s/^helo:\s*\r?\n(?:rcpt|ssub)?\s*\r?\n?//o;
        $mail = transliterate(\$mail,0);
        goto TRANSLITONLY;
    }
    if ($qs{mailfrom}) {
        $fm .= "$qs{mailfrom} has requested this analyze report<br />\n";
    }
    if ($qs{classification}) {
        $fm .= "analyze report reason is a $qs{classification}<br />\n";
    }
    if ($maillength > length($mail)) {
        $fm .= "analyze is restricted to a maximum length of $mBytes bytes<br />\n";
        $fm .= "attachments will be fully analyzed using SPAMBOX_AFC<br />\n" if (${'DoSPAMBOX_AFC'});
        $fm .= "attachments will be fully scanned for viruses<br />\n" if (($UseAvClamd && $CanUseAvClamd) || ($DoFileScan && $FileScanCMD));;
    }
    if ($normalizeUnicode && $CanUseUnicodeNormalize) {
        $fm .= "text processing uses unicode normalization<br />\n";
    }
    if ($mail =~ /X-Assp-ID: (.+)/io) {
        $fm .= "SPAMBOX-ID: $1<br />";
    }
    if ($mail =~ /X-Assp-Session: (.+)/io) {
        $fm .= "SPAMBOX-Session: $1<br />";
    }
    my $reportedBy;
    my ($xorgsub) = $mail =~ /X-Assp-Original-Subject:\s*($HeaderValueRe)/ios;
    $xorgsub =~ s/[\r\n]+$//o;
    if ($mail =~ s/X-Assp-Envelope-From:\s*($HeaderValueRe)//ios) {
        my $s = $1;
        &headerUnwrap($s);
        if ($s =~ /($EmailAdrRe\@$EmailDomainRe)/io) {
            $s = batv_remove_tag(0,lc $1,'');
            $mailfrom = $s;
            $fm{$s}=1;
            ($emfd) = $s =~ /\@([^@]*)/o;
        }
        $hasheader = 1;
    }
    if (! scalar keys %to && $mail =~ s/X-Assp-Intended-For:\s*($HeaderValueRe)//ios) {
        my $s = $1;
        &headerUnwrap($s);
        if ($s =~ /($EmailAdrRe\@$EmailDomainRe)/io) {
            $s = batv_remove_tag(0,lc $1,'');
            $reportedBy ||= $s;
            $to{$s}=1;
        }
        $hasheader = 1;
    }
    if ($mail =~ s/X-Assp-Recipient:\s*($HeaderValueRe)//ios) {
        my $s = $1;
        &headerUnwrap($s);
        if ($s =~ /($EmailAdrRe\@$EmailDomainRe)/o) {
            $s = batv_remove_tag(0,lc $1,'');
            $reportedBy ||= $s;
            $to{$s}=1;
        }
        $hasheader = 1;
    }
    $fm .= "removed all local X-SPAMBOX- header lines for analysis<br />\n"
        if ($mail =~ s/x-assp-[^()]+?:\s*$HeaderValueRe//gios);
    my $mystatus;
    my $foundReceived = 0;
    my @t;
    my $ret;
    my $bombsrch;
    my $orgmail;
    my @sips;
    my $sub = undef;
    my $wildcardUser = lc $wildcardUser;
    my $headerLen = index($mail,"\015\012\015\012");
    if ($hasheader && $headerLen == -1) {
        $mail .= "\015\012\015\012";
        $headerLen = index($mail,"\015\012\015\012");
    }

    if ($mail) {
        $orgmail = $mail;
        my $name = $myName;
        $name =~ s/(\W)/\\$1/go;
        if ($headerLen > -1) {
            my $fhh;
            do {
               $fhh = rand(1000000);
            } while exists $Con{$fhh};
            $mail = "$xorgsub\r\n".$mail if ($xorgsub && $mail !~ /(?:^|\n)subject:/o );
            $Con{$fhh}->{header} = $mail;
            $Con{$fhh}->{headerpassed} = 1;
            &makeSubject($fhh);
            $sub = $Con{$fhh}->{subject3} if defined $Con{$fhh}->{subject3};
            headerUnwrap($sub) if (defined $sub);
            delete $Con{$fhh};
        }

        my @myNames = ($myName);
        push @myNames , split(/[\|, ]+/o,$myNameAlso);
        my $myName = join('|', map {my $t = quotemeta($_);$t;} @myNames);
        my ($header) = $mail =~ /($HeaderRe+)/o;
        my @recHeader;
        if ($header) {
            while ( $header =~ /Received:($HeaderValueRe)/giso ) {
                my $val = $1;
                push @recHeader, $val;
                if ( $val =~ /\s+from\s+.*?\(\[($IPRe).*?helo=(.{0,64})\)(?:\s+by\s+(?:$myName))?\s+with/isg ) {
                    $ip = ipv6expand(ipv6TOipv4($1));
                    $helo = $2;
                    $foundReceived = -1;
                }
            }
        }
        if (! $ip && $mail =~ /(?:^[\s\r\n]*|\r?\n)\s*ip\s*=\s*($IPRe)/ios ) {
            $ip = ipv6expand(ipv6TOipv4($1));
            $mystatus="ip";
        }
        
		$fm .= "Connecting IP: '$ip'<br />\n" if $ip;
        my $conIP = $ip;
        $ip3 = ipNetwork($ip,1);
        if (!$helo && $mail =~ /(?:^[\s\r\n]*|\r?\n)\s*helo\s*=\s*([^\r\n]+)/ios ) {
            $helo = $1;
            $helo =~ s/\)$//o;
            $mystatus="helo";
        }
        $fm .= "Connecting HELO: $helo<br />\n" if $helo;
        if ( $foundReceived != -1 && $mail =~ /(?:^[\s\r\n]*|\r?\n)\s*text\s*=\s*(.+)/ios ) {
            $text = $1;
            $mystatus="text";
            $fm .= "found 'text=TEXT' - lookup regular expressions in TEXT <br />\n";
        } else {
            $text = $mail;
        }
        $text =~ s/(?:\r?\n)+/\r\n/gos if $mystatus;
        my $textheader;
        if ($headerLen > -1 ) {
            $textheader = substr($text,0,$headerLen);
        } else {
            $textheader = $text;
        }
        my $nutext = $text;
        unicodeNormalize(\$nutext);
        $fm = "<div class=\"textBox\"><b><font size=\"3\" color=\"#003366\">General Hints:</font></b><br /><br />\n$fm</div>\n" if $fm;
        $fm .= "<div class=\"textBox\"><br />";
        if (@recHeader) {
            my $ispHost;
            my @authHosts;
            for my $val ( @recHeader ) {
                if ($ispHostnames && $val =~ /(\s*from\s+(?:([^\s]+)\s)?(?:.+?)($IPRe)(?:.{1,80})by.{1,20}($ispHostnamesRE))/gis ) {
                    my ($r,$h,$i,$ih) = ($1,$2,$3,$4);
                    next if $i =~ /^$IPprivate$/o;
                    $helo = $h;
                    $received = 'Received:'.$r;
                    $ispHost = $ih;
                    $ip = ipv6expand(ipv6TOipv4($i));
                    $ip3 = ipNetwork($ip,1);
                    $foundReceived = 1;
                }
                &headerSmartUnwrap($val);
                if ($val =~ /\s*from\s+(?:([^\s]+)\s)?(?:.+?)($IPRe)(?:.{1,80})by\s+($HostRe).+?with\s+(E?SMTPS?A)/gio ) {
                    my $auth = {};
                    $auth->{host} = $1;
                    $auth->{ip} = $2;
                    $auth->{by} = $3;
                    $auth->{mech} = uc $4;
                    unshift(@authHosts,$auth);
                }
            }
            if ($received) {
                $fm =~ s/(Connecting IP: '[^']+')/$1 is an <a href='.\/ispip'>ISPIP<\/a>/o;
                $fm =~ s/(Connecting HELO: [^<]+)/$1 is HELO from ISP-host: <a href='.\/ispHostnames'>$ispHost<\/a>/o;
                $fm .= "<b><font color='orange'>&bull;</font>ISP/Secondary Header:</b>'$received'<br />\n";
                $fm .= "<b><font color='orange'>&bull;</font>Switched to ISP/Secondary IP:</b> '$ip'<br /><br />\n";
            }
            if (@authHosts) {
                $fm .= "<b><font color=\"#003366\">host and sender authentications:</font></b><br />";
                $fm .= "host '$_->{host} ($_->{ip})' authenticated to '$_->{by}' using '$_->{mech}'<br />\n" for @authHosts;
                $fm .= "<br />\n";
            }
        }
        @recHeader = ();
        
        if ($foundReceived <= 0 && !$mystatus) {
            $foundReceived += () = $mail =~ /(Received:\s*from\s*)/isgo;
            $fm .= "<b><font color='yellow'>&bull;</font>no foreign received header line found</b><br /><br />\n"
              if ($foundReceived <= 0) ;
        }

        $fm .= "<b><font color=\"#003366\">sender and reply addresses:</font></b><br />";
        $fm .=  "MAIL FROM: $mailfrom<br />  " if $mailfrom;
        my $noDKIM;
        while ($header =~ /($HeaderNameRe):($HeaderValueRe)/igos) {
            push @recHeader, $1, $2;
            my $who = $1;
            my $s = $2;
            $noDKIM = 1 if $who =~ /^X-SPAMBOX-[^(]+?\(\d+\)/io;
            next if $who !~ /^(from|sender|reply-to|errors-to|list-\w+|ReturnReceipt|Return-Receipt-To|Disposition-Notification-To)$/io;
            $mailfrom = lc($1) if (! $mailfrom && lc($1) eq 'from');
            &headerUnwrap($s);
            while ($s =~ /($EmailAdrRe\@$EmailDomainRe)/go) {
                my $ss = batv_remove_tag(0,$1,'');
                $mailfrom = $ss if $mailfrom eq 'from';
                $fm{lc $ss}=1;
                $fm .=  " $who: $ss <br />  ";
            }
        }
        $fm =~ s/  $/<br \/>/o;

        $fm .= "<b><font color=\"#003366\">recipient addresses:</font></b><br />";
        foreach (keys %to) {
            $fm .=  "RCPT TO: $_ <br />  ";
            my $newadr = RcptReplace($_,$mailfrom,'RecRepRegex');
            $fm =~ s/,$/(replaced with $newadr),/o if lc($newadr) ne lc $_;
        }
        while (@recHeader) {
            my $who = shift(@recHeader);
            my $s = shift(@recHeader);
            next if $who !~ /^(?:to|cc|bcc)$/io;
            &headerUnwrap($s);
            while ($s =~ /($EmailAdrRe\@$EmailDomainRe)/go) {
                my $ss = batv_remove_tag(0,$1,'');
                $to{lc $ss}=1;
                $headTo ||= $s if (lc $who eq 'to');
                $reportedBy ||= $s;
                $fm .=  " $who: $ss <br />  ";
            }
        }
        $org_headTo = $headTo;
        $headTo = RcptReplace($headTo,$mailfrom,'RecRepRegex') if $headTo;
        
	    if ($enhancedOriginIPDetect) {
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{rcpt} = join(' ',keys %to);
            my ($ips,$ptr,$oip) = getOriginIPs(\$mail,$ip,$ip,'ptr',$tmpfh);
            delete $Con{$tmpfh};
            @sips = @{$ips};
            my @showIPs;
            for (my $i = 0; $i < @sips; $i++) {
                push @showIPs , $sips[$i]. ($ptr->{$sips[$i]} ? '('.$ptr->{$sips[$i]}.')' : '(no PTR)');
            }
            if ($oip) {
                $fm .= "<b><font color='green'>using enhanced Originated IP detection</font></b><br />\n" ;
                $fm .= "<font color='yellow'>&bull;</font>detected IP\'s on the mail routing way: ".join('<br />', @showIPs)."<br />\n";
                $fm .= "<font color='yellow'>&bull;</font>detected source IP: $oip<br /><br />\n";
            }
        } else {
            $fm .= "<b><font color='red'>enhanced Originated IP detection is disabled</font></b><br />\n";
        }
        push @sips, $ip if $ip;

        if ($reportedBy && $mailfrom && $NotSpamTag) {
            $fm .= "<br />\n<b><font color=\"#003366\">NotSpamTag:</font></b><br />";
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{mailfrom} = $mailfrom;
            $Con{$tmpfh}->{rcpt} = $reportedBy;
            if (my $tag = NotSpamTagGen($tmpfh)) {
                $fm .= "a possible NotSpamTag for this mail is : <b>$tag</b>  ";
            }
            delete $Con{$tmpfh}->{notspamtag};
            if ($sub) {
                while ($sub =~ /\b[\'\"\[\(]?([0a-zA-Z2-7]{10})[\'\"\]\)]?\b/og) {
                    last if NotSpamTagOK($tmpfh,$1);
                }
                $Con{$tmpfh}->{myheader} =~ s/\r\n$//o;
                $Con{$tmpfh}->{myheader} =~ s/\r\n/<br \/>\n/o;
                $Con{$tmpfh}->{myheader} =~ s/X-Assp-//go;
                $fm .= "<br />\n<b>$Con{$tmpfh}->{myheader}</b>  ";
            }
            delete $Con{$tmpfh};
        }

        $reportedBy = '' unless ($DoPrivatSpamdb && localmailaddress(0, $reportedBy));
        $fm =~ s/  $/<br \/><br \/>\n/o;

        $fm .= "<b><font size=\"3\" color=\"#003366\">Feature Matching:</font></b><br /><br />";

        $fm .= "<b><font color='red'>&bull;</font>this mail would be blocked by the crash prevention analyzer</b><br />\n"
            if (!$mystatus && $crashHMM && HMMwillPossiblyCrash(0,\$text));

        my $grouphint;
        if ($Groups =~ /\s*file\s*:\s*(.+)$/i) {
            my $file = $1;
            $grouphint =
"\"javascript:void(0);\" onclick=\"javascript:popFileEditor('$file',1);\" onmouseover=\"showhint('edit Groups definition file $file', this, event, '250px', '1'); return true;\"";
        } else {
            $grouphint = "'./#Groups'";
        }
        
        foreach my $ad (sort keys %fm ) {
            my $mf = $ad;
            my $mfd;
            $mfd = $1 if $mf =~ /\@([^@]*)/o;
            my $mfdd;
            $mfdd = $1 if $mf =~ /(\@[^@]*)/o;

            if (matchSL( $mf, 'noProcessing' )) {
                $fm .=
"<b><font color='orange'>&bull;</font> <a href='./#noProcessing'>NoProcessing</a></b>: '$mf'<br />\n";
              }
            if ( $noProcessingDomains && $mf =~ /($NPDRE)/ ) {
                $fm .=
"<b><font color='orange'>&bull;</font> <a href='./#noProcessingDomains'>NoProcessing Domain</a></b>: '$1'<br />\n";
              }
            if ( matchSL( $mf, 'noProcessingFrom' ) ) {
                $fm .=
"<b><font color='orange'>&bull;</font> <a href='./#noProcessingFrom'>NoProcessing Addresses From</a></b>: '$mf'<br />\n";
              }
            if ($blackListedDomains && matchRE([$mf],'blackListedDomains',1) ) {
                $fm .=
"<b><font color='red'>&bull;</font> <a href='./#blackListedDomains'>Blacklisted Domains</a></b>: '$lastREmatch'<br />\n";
              }
            foreach (keys %to) {
                if ($blackListedDomains && matchRE(["$mf,$_"],'blackListedDomains',1) ) {
                    $fm .=
"<b><font color='red'>&bull;</font> <a href='./#blackListedDomains'>Blacklisted Domains</a></b>: '$lastREmatch'<br />\n";
                  }
            }
            if ($whiteListedDomains && matchRE([$mf],'whiteListedDomains',1) ) {
                $fm .=
"<b><font color=#66CC66>&bull;</font> <a href='./#whiteListedDomains'>Whitelisted Domains</a></b>: '$lastREmatch'<br />\n";
              }
            foreach (keys %to) {
                if ($whiteListedDomains && matchRE(["$mf,$_"],'whiteListedDomains',1) ) {
                    $fm .=
"<b><font color=#66CC66>&bull;</font> <a href='./#whiteListedDomains'>Whitelisted Domains</a></b>: '$lastREmatch'<br />\n";
                  }
            }
            $fm .= "<b><font color='orange'>&bull;</font> <a href='./lists'>Redlist</a></b>: '$ad'<br />\n"
              if $Redlist{$ad};
            $fm .=
"<b><font color=#66CC66>&bull;</font> <a href='./lists'>Redlisted Domain/ Wildcard</a></b>: '$wildcardUser$mfdd'<br />\n"
              if $Redlist{"$wildcardUser$mfdd"};
            $fm .=
"<b><font color=#66CC66>&bull;</font> <a href='./lists'>Whitelisted WildcardDomain</a></b>: '$wildcardUser$mfdd'<br />\n"
              if &Whitelist("$wildcardUser$mfdd");

            if (! $WhitelistPrivacyLevel) {
                if (&Whitelist($ad)) {
                    $fm .= "<b><font color=#66CC66>&bull;</font> <a href='./lists'>On Global Whitelist</a></b>: '$ad'<br />\n";
                    foreach my $t (sort keys %to) {
                        if (! &Whitelist($ad,$t)) {
                            $fm .= "<b><font color='red'>&bull;</font> <a href='./lists'>Whitelist removed for $t </a></b>: '$ad'<br />\n";
                        }
                    }
                }
            } elsif ($WhitelistPrivacyLevel==1) {
                my %seen;
                foreach my $t (sort keys %to) {
                    my $dom;
                    $dom = $1 if $t =~ /(\@$EmailDomainRe)$/o;
                    if ($dom && ! exists($seen{$dom}) && &Whitelist($ad,$dom)) {
                        $fm .= "<b><font color=#66CC66>&bull;</font> <a href='./lists'>On Domain Whitelist</a></b>: '$ad,$dom'<br />\n";
                        $seen{$dom} = 1;
                    }
                    if (! &Whitelist($ad,$t)) {
                        $fm .= "<b><font color='red'>&bull;</font> <a href='./lists'>Whitelist removed for $t </a></b>: '$ad'<br />\n";
                    }
                }
            } elsif ($WhitelistPrivacyLevel==2) {
                foreach my $t (sort keys %to) {
                    if (&Whitelist($ad,$t)) {
                        $fm .= "<b><font color=#66CC66>&bull;</font> <a href='./lists'>On Privat Whitelist</a></b>: '$ad,$t'<br />\n";
                    } elsif (exists $Whitelist{"$ad,$t"}) {
                        $fm .= "<b><font color='red'>&bull;</font> <a href='./lists'>Whitelist explicide removed for $t </a></b>: '$ad'<br />\n";
                    }
                }
            }

            foreach my $t (sort keys %to) {
                $fm .=
"<b><font color='red'>&bull;</font> <a href='./#persblackdb'>on personal Blacklist for $t </a></b>: '$ad'<br />\n"
                    if PersBlackFind($t,$ad);
            }
            
            $fm .=
"<b><font color=#66CC66>&bull;</font> <a href='./#noURIBL'>No URIBL sender</a></b>: '$mf'<br />\n"
              if matchSL( $mf, 'noURIBL' );

            while (my ($k,$v) = each %GroupRE) {
                my $cfglist;
                foreach my $config (keys %{$GroupWatch{$k}}) {
                    $cfglist .= $cfglist ? ', ' : "- $k is used in: ";
                    if ($Config{$config} =~ /\s*file\s*:\s*(.+)$/i) {
                        my $file = $1;
                        $cfglist .=
"<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('$file',1);\" onmouseover=\"showhint('edit file $file', this, event, '250px', '1'); return true;\">$config</a>";
                    } else {
                        $cfglist .= "<a href='./#$config'>$config</a>";
                    }
                }
                my $gpexplnk =
"<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('files/groups_export/$k.txt',8);\" onmouseover=\"showhint('show group details in exported file files/groups_export/$k.txt', this, event, '250px', '1'); return true;\">$k</a>";
                $fm .=
"<b><font color=#66CC66>&bull;</font> <a href=$grouphint>Group</a> $gpexplnk</b> match for: '$mf' $cfglist<br />\n"
                    if ($v && $mf && eval{$mf =~ /$v/i});
                $fm .=
"<b><font color=#66CC66>&bull;</font> <a href=$grouphint>Group</a> $gpexplnk</b> match for: '$mfd' $cfglist<br />\n"
                    if ($v && $mfd && eval{$mfd =~ /$v/i});
                $fm .=
"<b><font color=#66CC66>&bull;</font> <a href=$grouphint>Group</a> $gpexplnk</b> match for: '$mfdd' $cfglist<br />\n"
                    if ($v && $mfdd && eval{$mfdd =~ /$v/i});
            }
        }

        foreach my $t (sort keys %to) {
            while (my ($k,$v) = each %GroupRE) {
                my $cfglist;
                foreach my $config (keys %{$GroupWatch{$k}}) {
                    $cfglist .= $cfglist ? ', ' : "- $k is used in: ";
                    if ($Config{$config} =~ /\s*file\s*:\s*(.+)$/i) {
                        my $file = $1;
                        $cfglist .=
"<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('$file',1);\" onmouseover=\"showhint('edit file $file', this, event, '250px', '1'); return true;\">$config</a>";
                    } else {
                        $cfglist .= "<a href='./#$config'>$config</a>";
                    }
                }
                my $gpexplnk =
"<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('files/groups_export/$k.txt',8);\" onmouseover=\"showhint('show group details in exported file files/groups_export/$k.txt', this, event, '250px', '1'); return true;\">$k</a>";
                $fm .=
"<b><font color=#66CC66>&nbsp;&bull;</font> <a href=$grouphint>Group</a> $gpexplnk</b> match for: '$t' $cfglist<br />\n"
                    if ($v && $t && eval{$t =~ /$v/i});
            }
        }

        $checkRegex && $preHeaderRe && SearchBomb( "preHeaderRe", $textheader );
        if ( $preHeaderRe && $text =~ /($preHeaderReRE)/ ) {
            $fm .= "<b><font color='red'>&bull;</font> <a href='./#preHeaderRe'>preHeaderRe</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "preHeaderRe", ($1||$2) );
            $fm .= "<font color='red'>&nbsp;&bull;</font> matching preHeaderRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $noSPFRe && SearchBomb( "noSPFRe", $mailfrom );
        if ( $noSPFRe && $mailfrom =~ /($noSPFReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#noSPFRe'>No SPF RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "noSPFRe", ($1||$2) );
            $fm .= "<font color='green'>&nbsp;&bull;</font> matching noSPFRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $noSPFRe && SearchBomb( "noSPFRe", $text );
        if ( $noSPFRe && $nutext =~ /($noSPFReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#noSPFRe'>No SPF RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "noSPFRe", ($1||$2) );
            $fm .= "<font color='green'>&nbsp;&bull;</font> matching noSPFRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $strictSPFRe && SearchBomb( "strictSPFRe", $mailfrom );
        if ( $strictSPFRe && $mailfrom =~ /($strictSPFReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#strictSPFRe'>Strict SPF RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "strictSPFRe", ($1||$2) );
            $fm .= "<font color='green'>&nbsp;&bull;</font> matching strictSPFRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $blockstrictSPFRe && SearchBomb( "blockstrictSPFRe", $mailfrom );
        if ( $blockstrictSPFRe && $mailfrom =~ /($blockstrictSPFReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#blockstrictSPFRe'>Block Strict SPF RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "blockstrictSPFRe", ($1||$2) );
            $fm .= "<font color='green'>&nbsp;&bull;</font> matching blockstrictSPFRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        if ( exists $SPFCache{"$ip $emfd"} ) {
            my ( $ct, $status, $result ) = split( ' ', $SPFCache{"$ip $emfd"} );
            my $color = (($status eq 'pass') ? 'green' : 'orange');
            $fm .= "<b><font color='$color'>&bull;</font> $ip is in SPFCache</b>: status=$status with helo=$result<br />\n";
          }

        if ($mailfrom && $DoDKIM) {
            my $mf = lc $mailfrom;
            my $domain;
            $domain = $1 if $mf=~/\@([^@]*)/o;
            if ($domain) {
                if ( ! $hasDKIM && DKIMCacheFind($domain)) {
                    $fm .= "<b><font color='red'>&bull;</font> DKIM-pre-check returned FAILED</b> missing DKIM-Signature for domain $domain<br />\n";
                }
            }
        }

        eval {
        my $tmpfh = time;
        $Con{$tmpfh} = {};
        $Con{$tmpfh}->{ip} = $ip;
        $Con{$tmpfh}->{mailfrom} = $mailfrom;
        $Con{$tmpfh}->{rcpt} = $headTo;
        $Con{$tmpfh}->{orgrcpt} = $org_headTo;
        $Con{$tmpfh}->{helo} = $helo;
        $Con{$tmpfh}->{header} = $completeMail;
        $Con{$tmpfh}->{nodkim} = $noDKIM;
        if ($hasDKIM) {
            $Con{$tmpfh}->{isDKIM} = 1;
            if ( DKIMOK($tmpfh,\$completeMail,defined${chr(ord(",")<< 1)} && ($completeMail =~ /\r\n\.[\r\n]+$/o)) ) {
                $fm .= "<b><font color='green'>&bull;</font> DKIM-check returned OK</b> $Con{$tmpfh}->{dkimverified}<br />\n";
            } else {
                $fm .= "<b><font color='red'>&bull;</font> DKIM-check returned FAILED</b> $Con{$tmpfh}->{dkimverified}<br />\n";
            }
        }

        DMARCget($tmpfh);

        if ($ip && ($mailfrom || $helo)) {
            if ( SPFok($tmpfh)) {
                $fm .= "<b><font color='green'>&bull;</font> SPF-check returned OK</b> for $ip -&gt; $mailfrom, $helo<br />\n";
                $fm .= "<font color='green'>&nbsp;&bull;</font> $Con{$tmpfh}->{received_spf}<br />\n" if $Con{$tmpfh}->{received_spf};
            } else {
                $fm .= "<b><font color='red'>&bull;</font> SPF-check returned FAILED</b> for $ip -&gt; $mailfrom, $helo<br />\n";
                $fm .= "<font color='red'>&nbsp;&bull;</font> $Con{$tmpfh}->{received_spf}<br />\n" if $Con{$tmpfh}->{received_spf};
            }
            if ($DoDKIM && $ValidateSPF && $Con{$tmpfh}->{dmarc} && $Con{$tmpfh}->{spf_result}) {
                if ( DMARCok($tmpfh)) {
                    $fm .= "<b><font color='green'>&bull;</font> DMARC-check returned OK</b><br />\n";
                } else {
                    $fm .= "<b><font color='red'>&bull;</font> DMARC-check returned FAILED</b><br />\n";
                }
            }
        }
        delete $Con{$tmpfh};
        $tmpfh = '';
        };
        
        $checkRegex && $whiteReRE && SearchBomb( "whiteRe", $text );
        if ( $whiteRe && $nutext =~ /($whiteReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#whiteRe'>White RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "whiteRe", ($1||$2) );
            $fm .= "<font color='green'>&nbsp;&bull;</font> matching whiteRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $redReRE && SearchBomb( "redRe", $text );
        if ( $redRe && $nutext =~ /($redReRE)/ ) {
            $fm .= "<b><font color='yellow'>&bull;</font> <a href='./#redRe'>Red RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "redRe", ($1||$2) );
            $fm .= "<font color='yellow'>&nbsp;&bull;</font> matching redRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $npReRE && SearchBomb( "npRe", $text );
        if ( $npRe && $nutext =~ /($npReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#npRe'>No Processing RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "npRe", ($1||$2) );
            $fm .= "<font color='green'>&nbsp;&bull;</font> matching npRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $baysSpamLoversRe && SearchBomb( "baysSpamLoversRe", $rcptto );
        if ( $baysSpamLoversRe && $rcptto =~ /($baysSpamLoversReRE)/ ) {
            $fm .=
"<b><font color='green'>&bull;</font> <a href='./#baysSpamLoversRe'>Bayes Spamlover RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "baysSpamLoversRe", ($1||$2) );
            $fm .=
"<font color='green'>&nbsp;&bull;</font> matching baysSpamLoversRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $SpamLoversRe && SearchBomb( "SpamLoversRe", $rcptto );
        if ( $SpamLoversRe && $rcptto =~ /($SpamLoversReRE)/ ) {
            $fm .= "<b><font color='green'>&bull;</font> <a href='./#SpamLoversRe'>Spamlover RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "SpamLoversRe", ($1||$2) );
            $fm .=
              "<font color='green'>&nbsp;&bull;</font> matching SpamLoversRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
          }
        $checkRegex && $testRe && SearchBomb( "testRe", $text);
        if ( $testRe && ($bombsrch = SearchBombW( "testRe", \$text ))) {
            if ( !$DoTestRe ) {
                $fm .=
"<i><font color='yellow'>&bull;</font> <a href='./#DoTestRe'>testRe</a> is <b>disabled because DoTestRe is disabled</b></i><br />\n";
              }
            $fm .= "<b><font color='yellow'>&bull;</font> <a href='./#testRe'>testRe</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='yellow'>&nbsp;&bull;</font> matching testRe($incFound): '$weightMatch'<br />\n";
          }

        $checkRegex && $contentOnlyRe && SearchBomb( "contentOnlyRe", $text);
        if ( $contentOnlyRe && $nutext =~ /($contentOnlyReRE)/ ) {
            $fm .=
"<b><font color='yellow'>&bull;</font> <a href='./#contentOnlyRe'>Restrict to Content Only RE</a></b>: '".($1||$2)."'<br />\n";
            $bombsrch = SearchBomb( "contentOnlyRe", ($1||$2) );
            $fm .=
              "<font color='yellow'>&nbsp;&bull;</font> matching contentOnlyRe($incFound): '$bombsrch'<br />\n"
              if $bombsrch;
        }

        $checkRegex && $bombRe && SearchBomb( "bombRe", $text);
        if ( $bombRe && ($bombsrch = SearchBombW( "bombRe", \$text ))) {
            if ( !$DoBombRe ) {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoBombRe'>bombRe</a> is <b>disabled because DoBombRe is disabled</b></i><br />\n";
              }
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .= "<b><font color='$color'>&bull;</font> <a href='./#bombRe'>bombRe </a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='$color'>&nbsp;&bull;</font> matching bombRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $bombDataRe && SearchBomb( "bombDataRe", $text);
        if ( $bombDataRe && ($bombsrch = SearchBombW( "bombDataRe", \$text ))) {
            if ( !$DoBombRe ) {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoBombRe'>BombData RE</a> is <b>disabled because DoBombRe is disabled</b></i><br />\n";
              }
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .= "<b><font color='$color'>&bull;</font> <a href='./#bombDataRe'>BombData RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='$color'>&nbsp;&bull;</font> matching bombDataRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $bombHeaderRe && SearchBomb( "bombHeaderRe", $textheader);
        if ( $bombHeaderRe && ($bombsrch = SearchBombW( "bombHeaderRe", \$textheader ))) {
            if ( !$DoBombHeaderRe ) {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoBombHeaderRe'>BombHeader RE</a> is <b>disabled</b></i><br />\n";
              }
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .= "<b><font color='$color'>&bull;</font> <a href='./#bombHeaderRe'>BombHeader RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='$color'>&nbsp;&bull;</font> matching bombHeaderRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && ($bombSubjectRe || $maxSubjectLength) && SearchBomb( "bombSubjectRe", $sub);
        if ( ($bombSubjectRe || $maxSubjectLength) && ($bombsrch = SearchBombW( "bombSubjectRe", \$sub)) ) {
            if ( !$DoBombHeaderRe ) {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoBombHeaderRe'>BombSubject RE</a> is <b>disabled</b> because DoBombHeaderRe is disabled</i><br />\n";
              }
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .= "<b><font color='$color'>&bull;</font> <a href='./#bombSubjectRe'>BombSubject RE</a></b>: '$bombsrch'<br />\n";
            $fm .=
              "<font color='$color'>&nbsp;&bull;</font> matching bombSubjectRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $bombCharSets && SearchBomb( "bombCharSets", $textheader);
        if ( $bombCharSets && ($bombsrch = SearchBombW( "bombCharSets", \$textheader ))) {
            if ( !$DoBombHeaderRe ) {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoBombHeaderRe'>bombCharSets</a> is <b>disabled</b> because DoBombHeaderRe is disabled</i><br />\n";
              }
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .=
              "<b><font color='$color'>&bull;</font> <a href='./#bombCharSetsRe'>BombCharsets RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='$color'>&nbsp;&bull;</font> matching bombCharSets($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $bombSuspiciousRe && SearchBomb( "bombSuspiciousRe", $text);
        if ( $bombSuspiciousRe && ($bombsrch = SearchBombW( "bombSuspiciousRe", \$text ))) {
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .=
"<b><font color='$color'>&bull;</font> <a href='./#bombSuspiciousRe'>BombSuspiciousRe RE</a></b>: '$bombsrch'<br />\n";
            $fm .=
"<font color='$color'>&nbsp;&bull;</font> matching bombSuspiciousRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $blackRe && SearchBomb( "blackRe", $text);
        if ( $blackRe && ($bombsrch = SearchBombW( "blackRe", \$text ))) {
            if ( !$DoBlackRe ) {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoBlackRe'>Black RE</a> is  <b>disabled</b></i><br />\n";
              }
            $fm .= "<b><font color='red'>&bull;</font> <a href='./#blackRe'>Black RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='red'>&nbsp;&bull;</font> matching blackRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $scriptRe && SearchBomb( "scriptRe", $text);
        if ( $scriptRe && ($bombsrch = SearchBombW( "scriptRe", \$text ))) {
            $fm .= "<b><font color='red'>&bull;</font> <a href='./#scriptRe'>Script RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='red'>&nbsp;&bull;</font> matching scriptRe($incFound): '$weightMatch'<br />\n";
          }
        $checkRegex && $bombSenderRe && SearchBomb( "bombSenderRe", $mailfrom);
        if ( $bombSenderRe && ($bombsrch = SearchBombW( "bombSenderRe", \$mailfrom )))
        {
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .= "<b><font color='$color'>&bull;</font> <a href='./#bombSenderRe'>BombSender RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='$color'>&nbsp;&bull;</font> matching bombSenderRe($incFound): '$weightMatch'<br />\n";
        }
        $checkRegex && $bombSenderRe && SearchBomb( "bombSenderRe", $ip);
        if ( $bombSenderRe && ($bombsrch = SearchBombW( "bombSenderRe", \$ip )))
        {
            my $color = $bombsrch =~ /\-\d+\s*$/o ? 'green' : 'red';
            $fm .= "<b><font color='$color'>&bull;</font> <a href='./#bombSenderRe'>BombSender RE</a></b>: '$bombsrch'<br />\n";
            $fm .= "<font color='$color'>&nbsp;&bull;</font> matching bombSenderRe($incFound): '$weightMatch'<br />\n";
        }


        my $obfuscatedip;
        my $obfuscateduri;
        my $maximumuniqueuri;
        my $maximumuri;
        if ( !$ValidateURIBL )
        {
            $fm .=
"<i><font color='red'>&bull;</font> <a href='./#ValidateURIBL'>URIBL check</a> is <b>disabled because ValidateURIBL is disabled</b></i><br />\n";
        } else {
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{mailfrom} = $mailfrom;
            $Con{$tmpfh}->{rcpt} = join(' ',keys %to);
            my $color = 'green';
            my $failed = 'OK';
            my $res = &URIBLok_Run($tmpfh,\$text,$ip,'');
            if (! $res) {
                $color = 'red';
                $failed = 'failed';
            } elsif ($Con{$tmpfh}->{messagereason}) {
                $color = 'yellow';
            }
            $fm .=
"<b><font color='$color'>&bull;</font> <a href='./#ValidateURIBL'>URIBL check</a></b>: '$failed'<br />\n";
            if ($Con{$tmpfh}->{messagereason}) {
                $color = 'orange';
                $fm .=
"<font color='$color'>&nbsp;&bull;</font> URIBL result: '$Con{$tmpfh}->{messagereason}'<br />
&nbsp;&nbsp; URIBL listed by: $Con{$tmpfh}->{uri_listed_by}<br />";
            }
            $obfuscatedip = $Con{$tmpfh}->{obfuscatedip};
            $obfuscateduri= $Con{$tmpfh}->{obfuscateduri};
            $maximumuniqueuri = $Con{$tmpfh}->{maximumuniqueuri};
            $maximumuri = $Con{$tmpfh}->{maximumuri};
            delete $Con{$tmpfh};
        }

        {
            $Email::MIME::ContentType::STRICT_PARAMS=0;
            $o_EMM_pm = 1;
            my ($email, @parts);
            eval {
                $email = Email::MIME->new($completeMail);
                fixUpMIMEHeader($email);
                @parts = parts_subparts($email);
            };
            if (${'DoSPAMBOX_AFC'} && $SPAMBOX_AFC::VERSION >= '3.08' && $baysConf > 0 && exists($preMakeRE{'SPAMBOX_AFCDetectSpamAttachReRE'}) && ${'SPAMBOX_AFCDetectSpamAttachRe'}) {
                my ($domain) = $reportedBy =~ /$EmailAdrRe(\@$EmailDomainRe)/io;
                my $re = ${'SPAMBOX_AFCDetectSpamAttachReRE'};
                foreach my $part ( @parts ) {
                    my $filename =   attrHeader($part,'Content-Type','filename','name')
                                  || $part->filename
                                  || attrHeader($part,'Content-Disposition','filename','name');
                    my $orgname = $filename;
                    my ($imghash,$imgprob);
                    if (   $orgname
                        && $part->header("Content-Type") =~ /($re)/is
                        && ($imghash = AttachMD5Part($part))
                        && mlog(0,"info: analyze calculated image hash '$imghash' for $1 - $orgname")
                        && defined($imgprob = $Spamdb{ "$reportedBy $imghash" } || $Spamdb{ "$domain $imghash" } || $Spamdb{ $imghash }))
                    {
                        if ($imgprob >= $baysProbability) {
                          $fm .= "<b><font color='red'>&bull;</font> <a href='./#SPAMBOX_AFCDetectSpamAttachRe'>spam attachment</a> ($1 - $orgname) found - spam probability is $imgprob</b><br />";
                        } elsif ($imgprob <= (1 - $baysProbability)) {
                          $fm .= "<b><font color='green'>&bull;</font> <a href='./#SPAMBOX_AFCDetectSpamAttachRe'>ham attachment</a> ($1 - $orgname) found - spam probability is $imgprob</b><br />";
                        } else {
                          $fm .= "<b><font color='yellow'>&bull;</font> <a href='./#SPAMBOX_AFCDetectSpamAttachRe'>neutral attachment</a> ($1 - $orgname) found - spam probability is $imgprob</b><br />";
                        }
                    }
                }
            }
            my $tmpfh = time;
            foreach my $part ( @parts ) {
                $Con{$tmpfh} = {};
                if ($UseAvClamd && $CanUseAvClamd) {
                    ClamScanOK($tmpfh,\$part->body);
                    $fm .= "<b><font color='red'>&bull;&nbsp;&dagger;&nbsp;&bull; $Con{$tmpfh}->{messagereason}</font></b><br />" if $Con{$tmpfh}->{messagereason};
                }
                $Con{$tmpfh} = {};
                if ($DoFileScan && $FileScanCMD) {
                    FileScanOK($tmpfh,\$part->body);
                    $fm .= "<b><font color='red'>&bull;&nbsp;&dagger;&nbsp;&bull; $Con{$tmpfh}->{messagereason}</font></b><br />" if $Con{$tmpfh}->{messagereason};
                }

                my $filename =   attrHeader($part,'Content-Type','filename','name')
                              || $part->filename
                              || attrHeader($part,'Content-Disposition','filename','name');
                my $orgname = $filename;

                my $self;
                if ($orgname && ${'DoSPAMBOX_AFC'} && $SPAMBOX_AFC::VERSION >= '3.08' && eval{$self = SPAMBOX_AFC->new()} ) {
                    $Con{$tmpfh} = {};
                    $self->{detectBinEXE} = 1;
                    $self->{blockEncryptedZIP} = ${'SPAMBOX_AFCblockEncryptedZIP'};
                    $self->{attZipRun} = sub { return 1 };
                    $Con{$tmpfh}->{rcpt} = "$reportedBy " if $reportedBy;
                    $Con{$tmpfh}->{rcpt} .= join(' ',keys %to);
                    $Con{$tmpfh}->{mailfrom} = $mailfrom;
                    if ($self->isAnEXE( \$part->body) ) {
                        $fm .= "<b><font color='orange'>&bull; attachment $orgname is an executable $self->{exetype}</font></b><br />";
                    } elsif (! $self->isZipOK( $Con{$tmpfh}, \$part->body, $orgname )) {
                        $fm .= "<b><font color='orange'>&bull; attachment : $self->{exetype}</font></b><br />";
                    }
                }
            }
            delete $Con{$tmpfh};
            $o_EMM_pm = 0;
        }

        my $cOK;
        ($mail,$cOK) = &clean( substr( $mail, 0, $mBytes ) );
        $mail =~ s/^helo:\s*\r?\nrcpt\s*\r?\n//o;

        if ($helo) {
            my $hb = $HeloBlack{ lc $helo };
            $fm .= "<b><font color='red'>&bull;</font> HELO Blacklist</b>: '$helo'</b><br />\n"
              if ( $hb >= 1);
            $fm .= "<b><font color='green'>&bull;</font> Known Good HELO</b>: '$helo'</b><br />\n"
              if ( $hb < 1 && $hb > 0);
            $fm .=
"<b><font color='#66CC66'>&bull;</font> <a href='./#heloBlacklistIgnore'>HELO Blacklist Ignore</a></b>: '$helo'</b><br />\n"
              if ( $heloBlacklistIgnore && $helo =~ /$HBIRE/ );
            if ( !$DoValidFormatHelo ) {
                $fm .= "<b><font color='orange'>&bull;</font>Valid Format of HELO not activated</b><br />\n";
              }
            if ($validFormatHeloRe) {
                if ( $helo =~ /$validFormatHeloReRE/ ) {
                    $fm .=
"<b><font color=#66CC66>&bull;</font> <a href='./#DoValidFormatHelo'>Valid Format of HELO</a></b>: '$helo'<br />\n";
                  } else {
                    $fm .=
"<b><font color='red'>&bull;</font> <a href='./#DoValidFormatHelo'>Not a Valid Format of HELO</a></b>: '$helo'<br />\n";
                  }
              }
            if ( !$DoInvalidFormatHelo ) {
                $fm .= "<b><font color='orange'>&bull;</font>Invalid Format of HELO not activated</b><br />\n";
              }

            $checkRegex && $invalidFormatHeloRe && SearchBomb( "invalidFormatHeloRe", $helo);
            if ( $invalidFormatHeloRe && ($bombsrch = SearchBombW( "invalidFormatHeloRe", \$helo )))
            {
                $fm .= "<b><font color='red'>&bull;</font> <a href='./#invalidFormatHeloRe'>Invalid Format of HELO</a></b>: '$bombsrch'<br />\n";
                $fm .= "<font color='red'>&nbsp;&bull;</font> matching invalidFormatHeloRe($incFound): '$weightMatch'<br />\n";
            }
            if ($DoIPinHelo) {
                my $tmpfh = time;
                $Con{$tmpfh} = {};
                $Con{$tmpfh}->{ip} = $ip;
                $Con{$tmpfh}->{helo} = $helo;
                my $color = 'green';
                my $failed = 'OK';
                my $res = &IPinHeloOK_Run($tmpfh);
                if (! $res) {
                    $color = 'yellow';
                    $failed = 'failed';
                }
                $fm .=
"<b><font color='$color'>&bull;</font> <a href='./#DoIPinHelo'>IP in Helo check</a></b>: '$failed'<br />\n";
                $fm .=
"<font color='$color'>&nbsp;&bull;</font> IP in Helo result: '$Con{$tmpfh}->{messagereason}'<br />\n" if $Con{$tmpfh}->{messagereason};
                delete $Con{$tmpfh};
            } else {
                $fm .=
"<i><font color='red'>&bull;</font> <a href='./#DoIPinHelo'>IP in Helo check</a> is <b>disabled because DoIPinHelo is disabled</b></i><br />\n";
            }
        }
        foreach my $iip (@sips) {
            if ( pbBlackFind($iip) ) {
                my $nip = &ipNetwork( $iip, $PenaltyUseNetblocks );
                $nip =~ s/\.d+$/.0/o;
                my ( $ct, $ut, $pbstatus, $value, $sip, $reason ) = split( ' ', $PBBlack{$iip} );
                ( $ct, $ut, $pbstatus, $value, $sip, $reason ) = split( ' ', $PBBlack{$nip} ) unless $ct;
                $fm .=
"<b><font color='red'>&bull;</font> $iip is in <a href='./#pbdb'>PB Black</a></b>: score:$value, last event - $reason<br />\n";
            }
        }
        if ( pbWhiteFind($ip) ) {
#            my ( $ct, $ut, $pbstatus, $reason ) = split( ' ', $PBWhite{$ip} );

            $fm .= "<b><font color=#66CC66>&bull;</font> $ip is in <a href='./#pbdb'>PB White</a></b><br />\n";
          }

        my $tmpfh = time;
        $Con{$tmpfh} = {};
        $Con{$tmpfh}->{rcpt} = join(' ',keys %to);
        if ( $ret = matchIP( $ip, 'noProcessingIPs', $tmpfh, 1 ) ) {
            my $f = $lastREmatch ? " for $lastREmatch" : '';
            $fm .=
"<b><font color='green'>&bull;</font> IP $ip is in <a href='./#noProcessingIPs'>noProcessing IPs</a>$f ($ret)</b><br />\n";
          }
        if ( $ret = matchIP( $ip, 'whiteListedIPs', $tmpfh, 1 ) ) {
            my $f = $lastREmatch ? " for $lastREmatch" : '';
            $fm .=
"<b><font color='green'>&bull;</font> IP $ip is in <a href='./#whiteListedIPs'>whiteListed IPs</a>$f ($ret)</b><br />\n";
          }
        delete $Con{$tmpfh};

        if ( $ret = matchIP( $ip, 'noPB', 0, 1 ) ) {
            $fm .=
              "<b><font color='green'>&bull;</font> IP $ip is in <a href='./#noPB'>noPB IPs</a> ($ret)</b><br />\n";
          }
        foreach my $iip (@sips) {
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{ip} = $iip;
            if ( exists $RBLCache{$iip} ) {
                my ( $ct, $mm, $status, @rbllists ) = split( ' ', $RBLCache{$iip} );
                if ($mm !~ /^\d{4}/o) {
                    $mm = '20'.$mm.':00';
                }
                $mm =~ s/\// /o;
                $status = ( $status == 2 ? 'as ok at '.$mm : "as not ok at $mm , listed by @rbllists" );
                my $res = RBLCacheOK_Run($tmpfh,$iip,1);
                my $result = ( $res ? 'OK ' : 'FAILED' );
                my $color = ($res ? ($Con{$tmpfh}->{messagereason} ? 'yellow' : 'green') : 'red');
                my $sum;
                $sum = ' - message score: '.(delete $Con{$tmpfh}->{rblweight}->{result})->[0] if exists $Con{$tmpfh}->{rblweight}->{result};
                $fm .=
                  "<b><font color='$color'>&bull;</font> RBLCacheCheck returned $result for $iip</b>: inserted $status$sum<br />\n";
                while (my ($k,$v) = each %{$Con{$tmpfh}->{rblweight}}) {
                    $fm .= "&nbsp;<font color='$color'>&bull;</font> RBLScore: $k -> $v<br />\n";
                }
            } else {
                my $res = RBLok_Run($tmpfh,$iip,1);
                my $color = ($res ? ($Con{$tmpfh}->{messagereason} ? 'yellow' : 'green') : 'red');
                my $status = ( $res ? 'OK ' : 'FAILED' );
                my $sum;
                $sum = ' - message score: '.(delete $Con{$tmpfh}->{rblweight}->{result})->[0] if exists $Con{$tmpfh}->{rblweight}->{result};
                $fm .=
                  "<b><font color='$color'>&bull;</font> RBLCheck returned $status for $iip</b>: $Con{$tmpfh}->{messagereason}$sum<br />\n";
                while (my ($k,$v) = each %{$Con{$tmpfh}->{rblweight}}) {
                    $fm .= "&nbsp;<font color='$color'>&bull;</font> RBLScore: $k -> $v<br />\n";
                }
            }
            delete $Con{$tmpfh};
        }

        {   # MXA check
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{ip} = $ip;
            $Con{$tmpfh}->{mailfrom} = $mailfrom;
            $Con{$tmpfh}->{header} = $textheader;
            MXAOK_Run($tmpfh);
            while (my ($k,$v) = each %{$Con{$tmpfh}->{MXAres}} ) {
                if ($v->{mx}) {
                    $fm .= "<b><font color='green'>&bull;</font> domain $v->{dom} (in $v->{tag}) has a valid MX record</b>: $v->{mx}<br />\n";
                }else {
                    $fm .= "<b><font color='red'>&bull;</font> domain $v->{dom} (in $v->{tag}) has no valid MX record</b><br />\n";
                }
                if ($v->{a}) {
                    $fm .= "<b><font color='green'>&bull;</font> domainMX $v->{mx} has a valid A record</b>: $v->{a}<br />\n";
                } else {
                    $fm .= "<b><font color='red'>&bull;</font> domainMX $v->{mx} has no valid A record</b><br />\n";
                }
            }
            delete $Con{$tmpfh};
        }

        {   # PTR check
            my ( $ct, $status, $dns ) = split( ' ', $PTRCache{$ip} );
            my $how = 'is in PTRCache';
            if (! $dns && ! $ct) {
                $dns = getRRData($ip,'PTR');
                $status = 0;
                $how = 'PTR record via DNS';
            }
            if ($dns && $status == 0) {   # still not verfied against valid and invalid
                if ($dns =~ /$validPTRReRE/) {
                    $status = 2;
                    PTRCacheAdd($ip,2,$dns);
                } elsif ($dns =~ /$invalidPTRReRE/) {
                    $status = 3;
                    PTRCacheAdd($ip,3,$dns);
                } else {
                    $status = 2;
                    PTRCacheAdd($ip,2,$dns);
                }
            }
            my %statList = (
                0 => 'no PTR',
                1 => 'no PTR',
                2 => "PTR OK - $dns",
                3 => "PTR NOTOK - $dns",
            );
            my $color = ($status == 2 ? 'green' : 'red');
            $status = $statList{$status};
            $fm .= "<b><font color='$color'>&bull;</font> $ip $how</b>: status=$status<br />\n";
        }

        if ( exists $RWLCache{$ip} ) {
            my ( $ct, $status ) = split( ' ', $RWLCache{$ip} );
            my %statList = (
                1 => 'tusted',
                2 => 'trusted but RWLminHits not reached',
                3 => 'trusted and whitelisted',
                4 => 'not listed'
            );
            my $color = ($status == 4 ? 'orange' : 'green');
            $status = $statList{$status};
            $fm .= "<b><font color='$color'>&bull;</font> $ip is in RWLCache</b>: status=$status<br />\n";
        } else {
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{ip} = $ip;
            my %statList = (
                1 => 'tusted',
                2 => 'trusted but RWLminHits not reached',
                3 => 'trusted and whitelisted',
                4 => 'not listed'
            );
            my $res = &RWLok_Run($tmpfh,$ip);
            $Con{$tmpfh}->{rwlstatus} = 4 if !$res && !$Con{$tmpfh}->{rwlstatus};
            if ($res) {
                my $color = ($Con{$tmpfh}->{rwlstatus} == 4 ? 'orange' : 'green');
                my $status = $statList{$Con{$tmpfh}->{rwlstatus}} || 'unknown';
                $Con{$tmpfh}->{messagereason} = ' - ' . $Con{$tmpfh}->{messagereason} if $Con{$tmpfh}->{messagereason};
                $fm .= "<b><font color='$color'>&bull;</font> RWLcheck returned OK for $ip </b>: status=$status$Con{$tmpfh}->{messagereason}<br />\n";
            }
            delete $Con{$tmpfh};
        }

        if ($ip && (my ( $cidr , $ct, $status, $data ) = SBCacheFind($ip)) ) {
            my %statList = (
                0 => 'not classified',
                1 => 'black country',
                2 => 'white SenderBase',
                3 => 'changed to black country'
            );
            my $color = 'orange';
            $color = 'red' if $status % 2;
            $color = 'green' if $status == 2;
            $status = $statList{$status};
            $data =~ s/\|/, /og;
            $fm .= "<b><font color='$color'>&bull;</font> $ip is in CountryCache</b>: status=$status, data=$data<br />\n";
        } elsif ($ip) {
            my $tmpfh = time;
            $Con{$tmpfh} = {};
            $Con{$tmpfh}->{ip} = $ip;
            $Con{$tmpfh}->{mailfrom} = $mailfrom;
            my %statList = (
                0 => 'not classified',
                1 => 'black country',
                2 => 'white SenderBase',
                3 => 'changed to black country'
            );
            my $res = SenderBaseOK($tmpfh, $ip);
            my $data = $Con{$tmpfh}->{sbdata};
            my $status = $Con{$tmpfh}->{sbstatus};
            my $color = 'orange';
            $color = 'red' if $status % 2;
            $color = 'green' if $status == 2;
            $status = $statList{$status};
            $data =~ s/\|/, /og;
            $fm .= "<b><font color='$color'>&bull;</font> $ip SenderBase</b>: status=$status, data=[$data]<br />\n" if $data;
            delete $Con{$tmpfh};
        }

        if ( $ret = matchIP( $ip, 'acceptAllMail', 0, 1 ) ) {
            $fm .=
"<b><font color='green'>&bull;</font> IP $ip is in <a href='./#acceptAllMail'>Accept All Mail</a> ($ret)</b><br />\n";
          }
        if ( $ret = matchIP( $ip, 'ispip', 0, 1 ) ) {
            $fm .=
"<b><font color='green'>&bull;</font> IP $ip is in <a href='./#ispip'>ISP/Secondary MX Servers</a> ($ret)</b><br />\n";
          }

        $tmpfh = time;
        $Con{$tmpfh} = {};
        $Con{$tmpfh}->{rcpt} = join(' ', keys %to);
        if ( $ret = matchIP( $ip, 'noDelay', $tmpfh, 1 ) ) {
            my $f = ($lastREmatch) ? " for $lastREmatch" : '';
            $fm .=
"<b><font color='green'>&bull;</font> IP $ip is in <a href='./#noDelay'>noDelay</a>$f ($ret)</b><br />\n";
        }
        foreach my $iip (@sips) {
            if ( $ret = matchIP( $iip, 'noBlockingIPs', $tmpfh, 1 ) ) {
                my $f = ($lastREmatch) ? " for $lastREmatch" : '';
                $fm .=
"<b><font color='green'>&bull;</font> IP $iip is in <a href='./#noBlockingIPs'>noBlockingIPs</a>$f ($ret)</b><br />\n";
            }
        }
        foreach my $iip (@sips) {
            if ( $ret = matchIP( $iip, 'denySMTPConnectionsFrom', $tmpfh, 1 ) ) {
                my $f = ($lastREmatch) ? " for $lastREmatch" : '';
                $fm .=
"<b><font color='red'>&bull;</font> IP $iip is in <a href='./#denySMTPConnectionsFrom'>denySMTPConnectionsFrom</a>$f ($ret)</b><br />\n";
            }
        }
        delete $Con{$tmpfh};

        foreach my $iip (@sips) {
            if ( $ret = matchIP( $iip, 'denySMTPConnectionsFromAlways', 0, 1 ) ) {
                $fm .=
"<b><font color='red'>&bull;</font> IP $iip is in <a href='./#denySMTPConnectionsFromAlways'>denySMTPConnectionsFromAlways</a>($ret)</b><br />\n";
            }
        }
        foreach my $iip (@sips) {
            if ( $ret = matchIP( $iip, 'droplist', 0, 1 ) ) {
                $fm .=
"<b><font color='red'>&bull;</font> IP $iip is in <a href='./#droplist'>droplist</a>($ret)</b><br />\n";
            }
        }
        my $v;
		if ($ip !~ /$IPprivate/o && ($v = $Griplist{$ip3})) {
		    $v = 0.01 if $v < 0.01;
		    $v = 0.99 if  $v > 0.99;
    	}
    	if ($griplist && ( !$mystatus ||  $mystatus eq "ip" )) {
            if ( $ispip  && matchIP( $ip, 'ispip', 0, 1 ) ) {
            	if ($ispgripvalue ne '') {
                    $v = $ispgripvalue;
                } else {
                    $v=$Griplist{x};
                }
            }

            $fm .= "<b><font color='gray'>&bull;</font> $ip3 has a Griplist value of $v</b><br />\n" if $v;

    	}

        if (! $qs{return}) {
            $fm =~ s/($IPRe)/my$e=$1;($e!~$IPprivate)?"<a href=\"javascript:void(0);\" title=\"take an action on that IP\" onclick=\"popIPAction('$1');return false;\">$1<\/a>":$e;/goe;
            $fm =~ s/(')?($EmailAdrRe?\@$EmailDomainRe)(')?/"<a href=\"javascript:void(0);\" title=\"take an action on that address\" onclick=\"popAddressAction('".&encHTMLent($2)."');return false;\">".&encHTMLent($1.$2.$3)."<\/a>";/goe;
        } else {
            $fm =~ s/<a href[^>]+>|<\/a>//go;
        }
        
        # Unicode Analyzes processing
        eval {
            $fm .= "<br /><hr><br />";
            $fm .= "<a href=\"http://perldoc.perl.org/perlunicode.html\" target=\"_blank\"><b><font size='3' color='#003366'>Unicode Analysis: using unicode version $UnicodeVersion</font></b></a><br /><br />\n";
            if (! $qs{return}) {
              $fm .= '<a id="plusu" href="javascript:void(0);" onclick="document.getElementById(\'unicode\').style.display = \'block\';this.style.display = \'none\';"><img src="get?file=images/plusIcon.png" /></a>';
              $fm .= "\n<div id=\"unicode\" style=\"display: none\">\n";
              $fm .= '<a href="javascript:void(0);" onclick="document.getElementById(\'unicode\').style.display = \'none\';document.getElementById(\'plusu\').style.display = \'block\';"><img src="get?file=images/minusIcon.png" />&nbsp;&nbsp;</a>';
            }
            my @tempfm;
            my $email = $mail;
            Encode::_utf8_on($email) unless is_7bit_clean(\$email);

            my $getChars = sub {
                my ($list,$s) = @_;
                foreach (@{$list}) {
                    next if $_ eq 'Common';
                    if ($email =~ /(\p{$_}{1,$s})/s) {
                        my $r = $1;
                        my @u;
                        eval {map{ push(@u, eU($_) , sprintf("U+%2.2X", unpack("U0U*",$_))) } split(//,$r);};
                        $r = eU($r);
                        Encode::_utf8_off($r);
                        push @tempfm , ($_ , $r, \@u);
                    }
                }
            };

            my $getHTML = sub {
                my $incLink = shift;
                while (@tempfm) {
                    my ($s,$r,$u) = (shift(@tempfm),shift(@tempfm),shift(@tempfm));
                    my $l = $s;
                    $l =~ s/ /+/go;
                    if ($incLink == 1) {
                        $r = "<a href=\"http://www.fontspace.com/unicode/block/$l\" target=\"_blank\">$r</a>";
                        $s = "<a href=\"http://www.fontspace.com/unicode/block/$l\" target=\"_blank\">$s</a>";
                    }
                    if ($incLink == 2) {
                        $r = "<a href=\"http://www.fontspace.com/unicode/script/$s\" target=\"_blank\">$r</a>";
                        $s = "<a href=\"http://www.fontspace.com/unicode/script/$s\" target=\"_blank\">$s</a>";
                    }
                    $fm.= '<tr><td>'.$s.'</td><td>'.$r.'</td><td>';
                    $fm.= "<table cellspacing='1' cellpadding='1' border='1'>\n";
                    $fm.='<tr>';
                    for (my $i=0; $i<@{$u}; $i+=2) {
                        $fm.= $incLink
                              ? "<th><a href=\"http://www.fontspace.com/unicode/analyzer/?q=$u->[$i]\" target=\"_blank\">$u->[$i]</a></th>"
                              : "<th>$u->[$i]</th>";
                    }
                    $fm.='</tr><tr>';
                    for (my $i=1; $i<@{$u}; $i+=2) {
                        my $c = $u->[$i-1];
                        $fm.= $incLink
                              ? "<th><a href=\"http://www.fontspace.com/unicode/analyzer/?q=$c\" target=\"_blank\">$u->[$i]</a></th>"
                              : "<th>$u->[$i]</th>";
                    }
                    $fm.='</tr>';
                    $fm .= "</table>\n";
                    $fm.= "</td></tr>\n";
                }
                $fm .= "</table>\n";
            };
            
            $getChars->(\@NonSymLangs,19);
            if (@tempfm) {
                $fm .= '<b>the following non symbolic unicode blocks were found:</b><br /><br />';
                $fm .= "<table cellspacing='5' cellpadding='2' border='1'>\n";
                $fm.= '<tr><th><a href="http://en.wikipedia.org/wiki/Unicode_block" target="_blank">Unicode Block  </a></th><th>example'."</th><th><a href=\"http://www.unicode.org/glossary/\" target=\"_blank\">example unicode points</a></th></tr>\n";
                $getHTML->(1);
            }
            @tempfm = ();
            $fm .= '<br />';

            $getChars->(\@SymLangs,14);
            if (@tempfm) {
                $fm .= '<b>the following symbolic unicode blocks were found:</b><br /><br />';
                $fm .= "<table cellspacing='5' cellpadding='2' border='1'>\n";
                $fm.= '<tr><th><a href="http://en.wikipedia.org/wiki/Unicode_block" target="_blank">Unicode Block  </a></th><th>example'."</th><th><a href=\"http://www.unicode.org/glossary/\" target=\"_blank\">example unicode points</a></th></tr>\n";
                $getHTML->(1);
            }
            @tempfm = ();
            $fm .= '<br />';

            $getChars->(\@UnicodeScripts,14);
            if (@tempfm) {
                $fm .= '<b>the following unicode scripts (except Common) were found:</b><br /><br />';
                $fm .= "<table cellspacing='5' cellpadding='2' border='1'>\n";
                $fm.= '<tr><th><a href="http://en.wikipedia.org/wiki/Script_(Unicode)" target="_blank">Unicode Script  </a></th><th>example'."</th><th><a href=\"http://www.unicode.org/glossary/\" target=\"_blank\">example unicode points</a></th></tr>\n";
                $getHTML->(2);
            }
            $fm .= '<br />Click on any block or script name or even on any character to get some more information.<br />';
            $fm .= "</div>\n" if (! $qs{return});
        } if($] ge '5.012000');

        $fm .= "<br /><hr><br />";
        my ($ar,$got,@t);
        if (! $lockBayes) {
            ($ar,$got) = BayesWords(\$mail,$reportedBy);
            push(@t, @$ar);
        } else {
            $got = {};
        }
        
        if ($obfuscatedip)     {push(@t,$URIBLaddWeight{obfuscatedip}); $got->{'URIBL-Obfuscated IP'} = $URIBLaddWeight{obfuscatedip};}
        if ($obfuscateduri)    {push(@t,$URIBLaddWeight{obfuscateduri}); $got->{'URIBL-Obfuscated URI'} = $URIBLaddWeight{obfuscateduri};}
        if ($maximumuniqueuri) {push(@t,$URIBLaddWeight{maximumuniqueuri}); $got->{'URIBL-Maximum(unique) URI'} = $URIBLaddWeight{maximumuniqueuri};}
        if ($maximumuri)       {push(@t,$URIBLaddWeight{maximumuri}); $got->{'URIBL-Maximum URI'} = $URIBLaddWeight{maximumuri};}

        if (!$mystatus) {
            my $bayestext;
            $bayestext = "<font color='red'>&bull; Bayesian Check is disabled</font>" if !$DoBayesian;
            $bayestext .= ' - word stemming engine is used' if eval{$SPAMBOX_WordStem::VERSION;};
            $bayestext .= ' - language '.$SPAMBOX_WordStem::last_lang_detect.' detected' if eval{$SPAMBOX_WordStem::last_lang_detect};
            $bayestext .= "<br /><font color='red'>&bull;</font> <b>Spamdb</b> has version: <b>$currentDBVersion{Spamdb}</b> - required version: <b>$requiredDBVersion{Spamdb}</b> !" if $currentDBVersion{Spamdb} ne $requiredDBVersion{Spamdb} && ! ($ignoreDBVersionMissMatch & 1);
            $ba .= "<b><font size='3' color='#003366'>Bayesian Analysis: $bayestext</font></b><br /><br />";

            if (! $qs{return}) {
              $ba .= '<a id="plusb" href="javascript:void(0);" onclick="document.getElementById(\'bayes\').style.display = \'block\';this.style.display = \'none\';"><img src="get?file=images/plusIcon.png" /></a>';
              $ba .= "\n<div id=\"bayes\" style=\"display: none\">\n";
              $ba .= '<a href="javascript:void(0);" onclick="document.getElementById(\'bayes\').style.display = \'none\';document.getElementById(\'plusb\').style.display = \'block\';"><img src="get?file=images/minusIcon.png" />&nbsp;&nbsp;</a>';
            }

            $ba .= "<br /><table cellspacing='0' cellpadding='0'>";
            $ba .= "<tr>
<td style=\"padding-left:5px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:right; font-size:small;\"><b>Bad Words</b></td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:left; font-size:small; background-color:#F4F4F4\"><b>Bad Prob&nbsp;</b></td>
<td style=\"padding-left:20px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:right; font-size:small;\"><b>Good Words</b></td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:left; font-size:small; background-color:#F4F4F4\"><b>Good Prob</b></td>
</tr>\n";
            my $bcount = 0;
            foreach (sort { abs( $got->{$main::b} - .5 ) <=> abs( $got->{$main::a} - .5 ) } keys %{$got} ) {
                last if ++$bcount > $maxBayesValues;
                my $g = sprintf( "%.4f", $got->{$_} );
                s/[<>]//go;
                s/[a-f0-9]{24}/[addr]/go;
                $_ = eU($_);
                s/^(private:|domain:)/<b>$1<\/b>/o;
                if ( $g < 0.5 ) {
                    $g = "$g <font color='red'>*</font>" if $g < 0.01 && $baysConf;
                    $ba .= "<tr>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">&nbsp;</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">&nbsp;</td>
<td style=\"padding-left:20px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">$_</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">$g</td>
</tr>\n";
                } else {
                    $g = "$g <font color='red'>*</font>" if $g > 0.99 && $baysConf;
                    $ba .= "<tr>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">$_</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">$g</td>
<td style=\"padding-left:20px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">&nbsp;</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">&nbsp;</td>
</tr>\n";
                }
            }
            $ba .= "</td></tr></table>\n";
            $ba .= "</div>\n" if (! $qs{return});
            my $bc = scalar @t;
            my $bcm = $bc > $maxBayesValues ? $maxBayesValues : $bc;
            my ($p1, $p2, $c1, $SpamProb, $SpamProbConfidence) = BayesHMMProb(\@t);
            my $hmmprob; my $hmmconf;

            if ($DoHMM) {
                my $tmpfh = time;
                $Con{$tmpfh} = {};
                $Con{$tmpfh}->{rcpt} = $reportedBy;
                &HMMOK_Run($tmpfh,\$mail);
                $hmmprob = $Con{$tmpfh}->{hmmprob};
                $hmmconf = $Con{$tmpfh}->{hmmconf};
                my $hmmres = ($Con{$tmpfh}->{hmmres} > $maxBayesValues) ? $maxBayesValues : $Con{$tmpfh}->{hmmres};
                if (defined $hmmprob) {
                    $hmmprob = sprintf("%.4f - got %d - used %d most significant results",$hmmprob,$Con{$tmpfh}->{hmmres},$hmmres);
                } elsif ($lockHMM) {
                    $hmmprob = 'got no result because the HMM database is locked by a rebuildspamdb task';
                } elsif (! $haveHMM) {
                    $hmmprob = 'got no result because the HMM database is empty';
                } else {
                    $hmmprob = 'got no result';
                }
                $hmmprob .= ' - Bayesian check would be skipped' if $Con{$tmpfh}->{skipBayes};
                
                $ba .= "<br /><hr><br /><b><font size='3' color='#003366'>HMM Analysis:</font></b>";
                $ba .= "<br /><font color='red'>&bull;</font> <b>HMMdb</b> has version: <b>$currentDBVersion{HMMdb}</b> - required version: <b>$requiredDBVersion{HMMdb}</b> !" if $currentDBVersion{HMMdb} ne $requiredDBVersion{HMMdb} && ! ($ignoreDBVersionMissMatch & 2);

                $ba .= "<br /><br />\n";

                if (! $qs{return}) {
                  $ba .= '<a id="plush" href="javascript:void(0);" onclick="document.getElementById(\'hmm\').style.display = \'block\';this.style.display = \'none\';"><img src="get?file=images/plusIcon.png" /></a>';
                  $ba .= "\n<div id=\"hmm\" style=\"display: none\">\n";
                  $ba .= '<a href="javascript:void(0);" onclick="document.getElementById(\'hmm\').style.display = \'none\';document.getElementById(\'plush\').style.display = \'block\';"><img src="get?file=images/minusIcon.png" />&nbsp;&nbsp;</a>';
                }

                $ba .= "<br /><table cellspacing='0' cellpadding='0'>
<tr>
<td style=\"padding-left:5px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:right; font-size:small;\"><b>Bad Sequences</b></td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:left; font-size:small; background-color:#F4F4F4\"><b>Bad Prob&nbsp;</b></td>
<td style=\"padding-left:20px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:right; font-size:small;\"><b>Good Sequences</b></td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:5; padding-bottom:5; text-align:left; font-size:small; background-color:#F4F4F4\"><b>Good Prob</b></td>
</tr>\n";

                my $bcount = 0;
                foreach (sort { abs( ${$Con{$tmpfh}->{hmmValues}}{$main::b} - .5 ) <=> abs( ${$Con{$tmpfh}->{hmmValues}}{$main::a} - .5 ) } keys %{$Con{$tmpfh}->{hmmValues}} ) {
                    last if ++$bcount > $maxBayesValues;
                    my $g = sprintf( "%.4f", ${$Con{$tmpfh}->{hmmValues}}{$_} );
                    s/[<>]//go;
                    s/[a-f0-9]{24}/[addr]/go;
                    $_ = eU($_);
                    s/^(private:|domain:)/<b>$1<\/b>/o;
                    if ( $g < 0.5 ) {
                        $g = "$g <font color='red'>*</font>" if $g < 0.01 && $baysConf;
                        $ba .= "<tr>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">&nbsp;</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">&nbsp;</td>
<td style=\"padding-left:20px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">$_</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">$g</td>
</tr>\n";
                    } else {
                        $g = "$g <font color='red'>*</font>" if $g > 0.99 && $baysConf;
                        $ba .= "<tr>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">$_</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">$g</td>
<td style=\"padding-left:20px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\">&nbsp;</td>
<td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:left; font-size:small; background-color:#F4F4F4\">&nbsp;</td>
</tr>\n";
                    }
                }

                $ba .= "</td></tr></table>\n";
                $ba .= "</div>\n" if (! $qs{return});
                %{$Con{$tmpfh}->{hmmValues}}=();
                delete $Con{$tmpfh};
            }
            @HmmBayWords = ();
            $haveSpamdb = getDBCount('Spamdb','spamdb') unless $haveSpamdb;
            $st .= "<br /><hr><br />";
            $st .=
"<b>The Bayesian database 'spamdb' is still unavailable, because it is locked by a rebuildspamdb task.</b><br /><br />" if $lockBayes;
            $st .=
"<b>The Bayesian database 'spamdb' is still unavailable, because it is empty.</b><br /><br />" if ! $haveSpamdb;
            $st .=
"<b><font size=\"3\" color=\"#003366\">Bayesian Spam Probability:</font></b><br /><br />\n<table cellspacing=\"0\" cellpadding=\"0\">";
            if ($baysConf) {
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>spamprobability</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f</td></tr>\n",
                $p1 );
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>hamprobability</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f</td></tr>\n",
                $p2 );
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>combined probability</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f - got %d - used %d most significant results</td></tr>\n",
                $SpamProb,$bc,$bcm );
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>bayesian confidence</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f</td></tr>\n",
                $SpamProbConfidence );
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>corpus confidence</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f</td></tr>\n",
                BayesConfNorm());
            } else {
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>combined probability</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f - got %d - used %d most significant results</td></tr>\n",
                $SpamProb,$bc,$maxBayesValues );
            }
            if ($DoHMM) {
                $st .= "</table>\n";
                $st .= "<br />Values marked with an <font color='red'>*</font>, are irrelevant for the confidence calculation.\n" if $baysConf;
                my $prob = $baysConf ? 'Probabilities' : 'Probability';
                $st .=
"<br /><hr><br /><b><font size=\"3\" color=\"#003366\">Hidden-Markov-Model Spam $prob:</font></b><br /><br />\n<table cellspacing=\"0\" cellpadding=\"0\">";
                $st .=
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>combined HMM spam probability</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">$hmmprob</td></tr>\n";
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>HMM confidence</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f</td></tr>\n",
                $hmmconf ) if $baysConf;
                $st .= sprintf(
" <tr><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; text-align:right; font-size:small;\"><b>corpus confidence</b>:</td><td style=\"padding-left:5px; padding-right:5px; padding-top:0; padding-bottom:0; font-size:small;\">%.8f</td></tr>\n",
                BayesConfNorm()) if $baysConf;
            }
 		}
        $st .= " </table><br />\n";
        $st .= "Values marked with an <font color='red'>*</font>, are irrelevant for the confidence calculation.<br />\n" if $baysConf;
        $st .= "</div><br />\n";
TRANSLITONLY:
        unless ($mystatus) {
            no warnings;
            fixutf8(\$mail);
            eval{$mail =~ s/<\s*\/\s*textarea\s*>/textarea/igo;};
            eval{$mail =~ s/<\s*\/?[^>]+>//gos;};
            eval{$mail =~ s/([^\n]{70,84}[^\w\n<\@])/$1\n/go;};
            eval{$mail =~ s/\s*\n+/\n/go;};
            eval{$mail =~ s/<|>//gos;};
        }
      }
      
      $mail = $orgmail if $mystatus;
      eval{$mail =~ s/\r//gos;};
      my $h1 = $WebIP{$ActWebSess}->{lng}->{'msg500060'} || $lngmsg{'msg500060'};
      my $h2 = $WebIP{$ActWebSess}->{lng}->{'msg500061'} || $lngmsg{'msg500061'};
      my $h3 = $WebIP{$ActWebSess}->{lng}->{'msg500062'} || $lngmsg{'msg500062'};
      my $h4 = $WebIP{$ActWebSess}->{lng}->{'msg500063'} || $lngmsg{'msg500063'};

      if ($qs{return}) {
          $qs{sub} = $sub;
          return <<EOT;
$fm$ba$st
EOT
      }
      my $trena = $DoTransliterate ? undef: ' (DoTransliterate is still switched off)';
      my $checked = $qs{translit} ? 'checked="checked"' : '';
      my $translit = $CanUseTextUnidecode
         ? <<EOT
<tr>
   <td class="noBorder">&nbsp;<input type="checkbox" name="translit" value="1" $checked/>&nbsp; transliterate the text to ASCII only$trena</td>
</tr>
EOT
         : undef
         ;
      return <<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<script type="text/javascript">
//<![CDATA[
function getInput() { return document.getElementById("mail").value; }
function setOutput(string) {document.getElementById("mail").value=string; }

function replaceIt() { try {
var findText = document.getElementById("find").value;
var replaceText = document.getElementById("replace").value;
setOutput(getInput().replace(eval("/"+findText+"/ig"), replaceText));
} catch(e){}}

//-->
//]]>
</script>
<div id="cfgdiv" class="content">
<h2>SPAMBOX Mail Analyzer</h2>
<div class="note">$h1
</div><br />
$fm$ba$st
<form action="" method="post">
    <table class="textBox">
        <tr>
            <td >
             <span style="float: left">Replace: <input type="text" id="find" size="20" /> with <input type="text" id="replace" size="20" /> <input type="button" value="Replace" onclick="replaceIt();" /></span>
            </td >
        </tr>
        <tr>
            <td class="noBorder" align="center">$h2<br />
            <textarea id="mail" name="mail" rows="10" cols="60" wrap="off">$mail</textarea>
            </td>
        </tr>
        $translit
        <tr>
            <td class="noBorder" align="center"><input type="submit" name="B1" value=" Analyze " /></td>
        </tr>
    </table>
</form>
<br />
<p class="note" ><small>$h3
<div class="textbox">
$h4</small></p>

</div>
</div>

$footers
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
  <input name="theButtonLogout" type="hidden" value="" />
</form>
</body></html>
EOT
}
