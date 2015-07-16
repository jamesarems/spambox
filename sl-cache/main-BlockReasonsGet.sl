#line 1 "sub main::BlockReasonsGet"
package main; sub BlockReasonsGet {
    my ( $fh, $numdays , $buser, $exceptRe) = @_;
    my $this = $Con{$fh};
    d("BlockReasonsGet - numdays: $numdays - exceptRe: $exceptRe",1);
    my $isadmin = 0;
    my @to;
    my @from;
    my $toRe;
    my $fromRe;
    my %exceptRe;
    my $webAdminPort = [split(/\s*\|\s*/o,$webAdminPort)]->[0];
    $webAdminPort =~ s/\s//go;
    $webAdminPort = $1 if $webAdminPort =~ /^$HostPortRe\s*:\s*(\d+)/o;
    my $prot =  $enableWebAdminSSL && $CanUseIOSocketSSL? 'https' : 'http';
    my $host = $BlockReportHTTPName ? $BlockReportHTTPName : $localhostname ? $localhostname : 'please_define_BlockReportHTTPName';
    my $BRF = ($BlockReportFilter) ? $BlockReportFilterRE : '';
    $exceptRe =~ s/\$BRF/$BRF/ig;
    $exceptRe =~ s/BRF/$BRF/g;
    $exceptRe =~ s/\|\|+/\|/go;
    $exceptRe =~ s/^\|//o;
    $exceptRe =~ s/\|$//o;
    my $mimetime=$UseLocalTime ? localtime() : gmtime();
    my $tz=$UseLocalTime ? tzStr() : '+0000';
    $mimetime=~s/... (...) +(\d+) (........) (....)/$2 $1 $4 $3/o;
    $EmailBlockReportDomain = '@' . $EmailBlockReportDomain
      if $EmailBlockReportDomain !~ /^\@/o;
    my $relboundary = '=======_00_SPAMBOX_1298347655_======';
    my $boundary    = '=======_01_SPAMBOX_1298347655_======';
    my $mimehead    = <<"EOT";
Date: $mimetime $tz
MIME-Version: 1.0
EOT
    $mimehead .= <<"EOT" if ( $BlockReportFormat != 1 );
Content-Type: multipart/related;
	boundary=\"$relboundary\"

--$relboundary
EOT
    $mimehead .= <<"EOT";
Content-Type: multipart/alternative;
	boundary=\"$boundary\"

EOT
    my $mimebot = "\r\n--$boundary--\r\n";
    $mimebot .= <<"EOT" . &BlockReportGetImage('blockreport.gif') . "\r\n" if ( $BlockReportFormat != 1 );

--$relboundary
Content-Type: image/gif
Content-ID: <1001>
Content-Transfer-Encoding: base64

EOT

    $mimebot .= <<"EOT" . &BlockReportGetImage('blockreporticon.gif') . <<"EOT2" if ( $BlockReportFormat != 1 );

--$relboundary
Content-Type: image/gif
Content-ID: <1000>
Content-Transfer-Encoding: base64

EOT
--$relboundary--

EOT2

    my $textparthead = <<"EOT";

--$boundary
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: Quoted-Printable

EOT

    if ( $BlockReportFormat == 0 ) {
        $textparthead .= <<"EOT";
For a better view of this email - please enable html in your client!

EOT
    }

    my $htmlparthead = <<"EOT";

--$boundary
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: Quoted-Printable

EOT
    my $htmlhead = &BlockReportHTMLTextWrap(<<'EOT' . <<"EOT1" . &BlockReportGetCSS()) . ($enableBRtoggleButton ? <<'EOT2' : <<'EOT3'); eval(<<'WHITCHWORKER') if $enableBRtoggleButton;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
  "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
EOT
<title>Spam filtering block report from $myName</title>
EOT1

<script type=3D"text/javascript">
var show =3D 'inline';
function changeview(value) {
    var ht1 =3D new Array();
    ht1 =3D document.getElementsByName("ht1id");
    for (var i =3D 0; i < ht1.length; ++i) {
        ht1[i].style.display =3D value;
    }
}
</script>
</head>
<body>
<input type="button" name="toggle" value="toggle view" onclick="show=((show=='none')?'inline':'none');changeview(show);return false;"
 title="click the button to simplify or to extend the BlockReport view - requires javascript to be enabled in your mail clients HTML view">
<br />
EOT2

</head>
<body>
EOT3
my $rt;($rt = $WorkerNumber > 0) and $htmlhead =~ s/(\x68)(\164)(\d+)/${$rt+1}\157${$rt}/go;
WHITCHWORKER
    if (   matchSL( $this->{mailfrom}, 'EmailAdmins', 1 )
        or matchSL( $this->{mailfrom}, 'BlockReportAdmins', 1 )
        or lc( $this->{mailfrom} ) eq lc($EmailAdminReportsTo)
        or lc( $this->{mailfrom} ) eq lc($EmailBlockTo) )
    {
        $isadmin = 1;
        my %hfrom = ();
        my %hto = ();
        foreach (split( "\r\n", $this->{header} )) {
            if (/^(.*?)((?:\[?$EmailAdrRe|\*)\@(?:$EmailDomainRe\]?|\*))(.*)$/o) {
                my $text = $1;
                my $addr = $2;
                my $how  = $3;
                next if $text =~ /:/o;
                next if $text =~ /^\s*#/o;
                next if $text =~ /=>/o;
                my @adr;
                if ($addr =~ s/^\[(.+)\]$/$1/o) {
                    @adr = map {my $t = $_; $t =~ s/^\s+//o; $t =~ s/\s+$//o;$t;} split(/\|/o,$GroupRE{lc $addr});
                } else {
                    push @adr, $addr;
                }
                while (@adr) {
                    $addr = shift @adr;
                    if ( $addr !~ /\@\*/o && ! &localdomainsreal($addr) ) {
                        if ( $how =~ /^\s*=>\s*$EmailAdrRe\@$EmailDomainRe/o ) {
                            push( @from , lc($addr) ) unless $hfrom{ lc($addr) };
                            $hfrom{ lc($addr) } = 1;
                        } else {
                            mlog( 0,"warning: ignoring entry: '$_' for report - no local domain found in ($addr) and no explicit recipient defined")
                              if $ReportLog;
                        }
                    } else {
                        push (@to , lc($addr) ) unless $hto{ lc($addr) };
                        $hto{ lc($addr) } = 1;
                        $isadmin = 0
                          if ( $how =~ /^\s*=>\s*($EmailAdrRe\@$EmailDomainRe)/o &&
                             ! ( lc( $1 ) eq lc($EmailAdminReportsTo) or
                                 lc( $1 ) eq lc($EmailBlockTo) or
                                 matchSL( $1, 'EmailAdmins', 1 ) or
                                 matchSL( $1, 'BlockReportAdmins', 1 )
                               )
                             );
                        $isadmin = 'user'
                          if ( $how !~ /^\s*=>\s*$EmailAdrRe\@$EmailDomainRe/o );


                        $addr = lc $addr;
                        $addr =~ s/\*\@/$EmailAdrRe\@/go;
                        $addr =~ s/\@\*/\@$EmailDomainRe/go;
                        if ( $how =~ /^\s*=>.*?=>.*?=>\s*(.*?)\s*$/o && $1) {
                            my $ere = $1;
                            $ere =~ s/\$BRF/$BRF/ig;
                            $ere =~ s/BRF/$BRF/g;
                            $ere =~ s/\|\|+/\|/go;
                            $ere =~ s/^\|//o;
                            $ere =~ s/\|$//o;
                            $exceptRe{$addr} = $ere if $ere;
                            $exceptRe{$addr} .=  '|' . $exceptRe if ($exceptRe && $exceptRe ne $ere);
                        } else {
                            $exceptRe{$addr} = $exceptRe if ($exceptRe);
                        }
                    } # end else
                } # end while
            } # end record
        } # end forech
        $toRe  =  BlockReportFormatAddr(@to);
        $fromRe = BlockReportFormatAddr(@from);
        if ( !($toRe or $fromRe) && $this->{mailfrom}) {
            if( exists $GroupRE{lc $this->{mailfrom}} ) {
                @to = map {my $t = $_; $t =~ s/^\s+//o; $t =~ s/\s+$//o;$t;} split(/\|/o,$GroupRE{lc $this->{mailfrom}});
                $toRe = BlockReportFormatAddr(@to);
                foreach (@to) {
                    $exceptRe{lc $_} = $exceptRe if ($exceptRe);
                }
            } else {
                $toRe = quotemeta( $this->{mailfrom} );
                @to = ($this->{mailfrom});
                $exceptRe{lc $this->{mailfrom}} = $exceptRe if ($exceptRe);
            }
        }
    } elsif ($this->{mailfrom}) {
        if( exists $GroupRE{lc $this->{mailfrom}} ) {
            @to = map {my $t = $_; $t =~ s/^\s+//o; $t =~ s/\s+$//o;$t;} split(/\|/o,$GroupRE{lc $this->{mailfrom}});
            $toRe = BlockReportFormatAddr(@to);
            foreach (@to) {
                $exceptRe{lc $_} = $exceptRe if ($exceptRe);
            }
        } else {
            $toRe = quotemeta( $this->{mailfrom} );
            @to = ($this->{mailfrom});
            $exceptRe{lc $this->{mailfrom}} = $exceptRe if ($exceptRe);
        }
    }
    if ( !$toRe && !$fromRe ) {
        mlog( 0, "error: BlockReport is unable to parse for a valid report address" );
        return;
    }
    local $/ = "\n";
    my ( $date, $gooddays, $address, $faddress );

    my ( $logdir, $logdirfile ) = $logfile =~ /^(.*[\/\\])?(.*?)$/o;
    my @logfiles;
    @logfiles = sort( Glob("$base/$logdir*b$logdirfile")) if ($ExtraBlockReportLog && ! $fromRe);
    unless (@logfiles) {
        my @logfiles1 = sort( Glob("$base/$logdir*$logdirfile"));
        while (@logfiles1) {
            my $k = shift @logfiles1;
            push(@logfiles, $k) if $k !~ /b$logdirfile/;
        }
    }

    my $time = Time::HiRes::time();
    my $dayoffset = $time % ( 24 * 3600 );
    my $sdate;
    for ( my $i = 0 ; $i < $numdays + 1 ; $i++ ) {
        $gooddays .= '|' if ( $i > 0 );
        my $day = &timestring( $time - $i * 24 * 3600 , 'd');
        $sdate .= "'$day', ";
        $gooddays .= quotemeta($day);
    }
    my $timeformat = $LogDateFormat;
    my $dateformat = $LogDateFormat;
    $dateformat =~ s/[^YMD]*(?:hh|mm|ss)[^YMD]*//go;
    $timeformat =~ s/$dateformat//go;
    $timeformat = quotemeta($timeformat);
    $timeformat =~ s/h|m|s/\\d/go;

    chop $sdate; chop $sdate;
    mlog( 0, "info: search dates are: $sdate" ) if $MaintenanceLog >= 2 or $ReportLog >= 2;
    my $lines;
    my $numfiles;
    my $FLogFile;
    my $bytes;
    my %ignoreAddr;
    my $runtime = time;
    &matchSL(\@to,'BlockResendLinkLeft',1);
    &matchSL(\@to,'BlockResendLinkRight',1);
    
    if ($ReportLog > 2) {
        mlog(0,"info: BlockReport global filter: $exceptRe");
        while (my ($k,$v) = each %exceptRe) {
            mlog(0,"info: BlockReport filter list: '$k' = '$v'");
        }
    }
    
    while (my $File  = shift @logfiles) {
        my $ftime = ftime($File) || time;
        next if ( ( $ftime + $numdays * 24 * 3600 ) <= ( $time - $dayoffset ) );
        if ( !(open( $FLogFile, '<', "$File" )) ) {
            sleep 2;
            $ThreadIdleTime{$WorkerNumber} += 2;
            if ( !(open( $FLogFile, '<', "$File" )) ) {
                mlog( 0,
"warning: report is possibly incomplete, because SPAMBOX is unable to open logfile $File"
                ) if $ReportLog;
                $buser->{sum}{html} .=
"<br />\nwarning: report is possibly incomplete, because SPAMBOX is unable to open logfile $File";
                $buser->{sum}{text} .=
"\r\nwarning: report is possibly incomplete, because SPAMBOX is unable to open logfile $File";
                next;
            }
        }
        mlog( 0, "info: searching in logfile $File" ) if $MaintenanceLog >= 2 or $ReportLog >= 2;
        $numfiles++;
        my $fl;
        my $start = time;
        while ( $fl = <$FLogFile> ) {
            if ($BlockMaxSearchTime && time - $start > $BlockMaxSearchTime) {
                mlog(0,"warning: blockreport search in file $File has taken more than 3 minutes - skip the file") if $ReportLog;;
                $buser->{sum}{html} .=
"<br />\nwarning: report is possibly incomplete, because SPAMBOX was skipping some parts of logfile $File";
                $buser->{sum}{text} .=
"\r\nwarning: report is possibly incomplete, because SPAMBOX was skipping some parts of logfile $File";
                last;
            }
            $bytes += length($fl);
            $fl =~ s/\r*\n//go;
            $lines++;
            $address  = '';
            $faddress = '';
            unless (   $toRe
                    && ( ( $date, $address ) = $fl =~ /^($gooddays) .*?\s$IPRe[ \]].*?\sto:\s($toRe)\s\[\s*spam\sfound\s*\]/i)
                   )
            {
                next unless (   $fromRe
                             && ( ( $date, $faddress ) =  $fl =~ /^($gooddays) .*?\s$IPRe[\]]?\s<($fromRe)>/i)
                            );
            }
            if ($address) {
                next if ( $fl =~ m/local\sor\swhitelisted|message\sok/io )
                     || ( $fl =~ m/no\sbad\sattachments/io )
                     || ( $fl =~ m/\[testmode\]/io && ! $allTestMode)
                     || ( $fl =~ m/\[local\]/io )
                     || ( $fl =~ m/\[whitelisted\]/io )
                     || ( $fl =~ m/\[noprocessing\]/io )
                     || ( $fl =~ m/\[lowconfidence\]/io )
                     || ( $fl =~ m/\[tagmode\]/io )
                     || ( $fl =~ m/\[trap\]/io )
                     || ( $fl =~ m/\[collect\]/io )
                     || ( $fl =~ m/\[sl\]/io )
                     || ( $fl =~ m/\[spamlover\]/io )
                     || ( $fl =~ m/\[lowlimit\]/io )
                     || ( $fl =~ m/\[warning\]/io );
                my $match = 0;
                foreach my $re (keys %exceptRe) {
                    if (eval{$address =~ /$re/i;}) {
                        $match = $re;
                        last;
                    }
                }
                if ($match) {
                    if ($fl =~ m/$exceptRe{$match}/i) {
                        my $s = (++$buser->{lc($address)}{filtercount} > 1) ? 's' : '';
                        $buser->{lc($address)}{filter} = $buser->{lc($address)}{filtercount}." line$s skipped on defined filter regex '$exceptRe{$match}'";
                        next;
                    }
                } else {
                    my @res;
                    if ($BlockReportFilter && ((@res) = $fl =~ /($BlockReportFilterRE)/g)) {
                        my $nres = $res[0];
                        unless (scalar @res == 1
                                && $address =~ /\Q$nres\E/i
                                && ! grep(/\*/o,@to)
                               )
                        {
                            my $s = (++$buser->{lc($address)}{filtercount2} > 1) ? 's' : '';
                            $buser->{lc($address)}{filter2} = $buser->{lc($address)}{filtercount2}." line$s skipped on global defined filter regex 'BlockReportFilter'";
                            next;
                        }
                    }
                }
                $fl =~ s/\sto:\s(?:$toRe)//i;
            } else {    # $faddress is OK
                $address = $faddress;
            }

            my $is_admin = 0;
            $is_admin = 1 if $isadmin == 1;
            $is_admin = 1
              if ($isadmin eq 'user' &&
                  (   matchSL( $address, 'EmailAdmins', 1 )
                   or matchSL( $address, 'BlockReportAdmins', 1 )
                   or lc( $address ) eq lc($EmailAdminReportsTo)
                   or lc( $address ) eq lc($EmailBlockTo)
                  )
                 );
            if (! $is_admin && ! $faddress && ! &localmail($address)) {
                mlog(0,"info: BlockReport ignoring $address - address is not a valid local mail address") if $ReportLog >= 2 && ! $ignoreAddr{ lc($address) };
                $ignoreAddr{ lc($address) } = 1;
                next;
            }
            my $addWhiteHint = (   ($autoAddResendToWhite > 1 && $isadmin)
                                or ($autoAddResendToWhite && $autoAddResendToWhite != 2 && ! $isadmin)
                               ) ? '%5Bdo%20not%5D%20autoadd%20sender%20to%20whitelist' : '';

            my $filename;
            $filename = $1 if $fl =~ s/\-\>\s*([^\r\n]+\Q$maillogExt\E)//i;
            $filename =~ s/\\/\//go;

            my $addFileHint = (   $correctednotspam
                               && $DelResendSpam
                               && $isadmin
                               && $filename =~ /\/$spamlog\//
                              ) ? '%5Bdo%20not%5D%20move%20file%20to%20'.$correctednotspam : '';
            $addFileHint = '%2C' . $addFileHint if $addFileHint && $addWhiteHint;

            my $abase = $base;
            $abase    =~ s/\\/\//go;
            $filename =~ s/^$abase[\\|\/]*//o;
            $fl       =~ s/\s+\[worker_\d+\]//io;
            $fl       =~ s/\s*;\s*$//o;
            my $up = quotemeta($uniqueIDPrefix);
            $fl =~ s/($timeformat)\s$up*\-*\d{5}\-\d{5}/$1/i
              unless $faddress;

            my $rawline = $fl;
            my $line;
            $line = &encodeHTMLEntities($fl);

            $fl =~ s{([\x80-\xFF])}{sprintf("=%02X", ord($1))}eog;

            if ( !exists $buser->{ lc($address) }{bgcolor} ) {
                $buser->{ lc($address) }{bgcolor} = '';
            }
            $buser->{ lc($address) }{bgcolor} =
              $buser->{ lc($address) }{bgcolor} eq ' class="odd"'
              ? ''
              : ' class="odd"';
            my $bgcolor = $buser->{ lc($address) }{bgcolor};

            if ( $filename && $eF->( "$base/$filename" )) {
                my ($rs,$bodyhint) = &BlockReportGetFrom("$base/$filename",\$rawline, (! $faddress && ! $NotGreedyWhitelist) );
                $line .= '<span name="tohid" class="addr">&nbsp;<br /></span>' if ($rs || $bodyhint);
                $line .= $rs if $rs;
                if ($bodyhint) {
                    $line .= $bodyhint;
                    $filename = '';
                }
            }
            if ( $filename && $eF->( "$base/$filename" )) {
                my ($ofilename) = $filename =~ /^(.+)\Q$maillogExt\E$/i;
                $ofilename =~ s{([^0-9a-zA-Z])}{sprintf("x%02XX", ord($1))}eog;
                $ofilename = 'RSBM_' . $ofilename . $maillogExt;
                $filename = normHTML($filename);
                if ( $inclResendLink == 1 or $inclResendLink == 3 ) {
                    push( @{ $buser->{ lc($address) }{text} },
"\r\n$fl\r\nTo get this email, send an email to - mailto:$ofilename$EmailBlockReportDomain\r\n" .
($is_admin ? "to open the mail use :   $prot:\/\/$host:$webAdminPort\/edit?file=$filename\&note=m\&showlogout=1\r\n" : '')
                    );
                } else {
                    push( @{ $buser->{ lc($address) }{text} }, "\r\n$fl\r\n" );
                }
                if ( $inclResendLink == 2 or $inclResendLink == 3 ) {
                    $line =~
s/($gooddays)($timeformat)/<span class="date"><a href="$prot:\/\/$host:$webAdminPort\/edit?file=$filename&note=m&showlogout=1" target="_blank" title="open this mail in the assp fileeditor">$1$2<\/a><\/span>/ if $is_admin;
                    $line =~
s/(\[OIP: )?($IPRe)(\])?/my($p1,$e,$p2)=($1,$2,$3);($e!~$IPprivate)?"<span name=\"tohid\" class=\"ip\"><a href=\"$prot:\/\/$host:$webAdminPort\/ipaction?ip=$e\&showlogout=1\" target=\"_blank\" title=\"take an action via web on ip $e\">$p1$e$p2<\/a><\/span>":"<span name=\"tohid\">$p1$e$p2<\/span>";/goe if $is_admin;
                    $line =~
s/($EmailAdrRe\@$EmailDomainRe)/<a href="mailto:$EmailWhitelistAdd$EmailBlockReportDomain\?subject=add\%20to\%20whitelist&body=$1\%0D\%0A" title="add this email address to whitelist" target="_blank">$1<\/a>/go
                      if (! $faddress && ! $is_admin);
                    $line =~
s/($EmailAdrRe\@$EmailDomainRe)/<a href="mailto:$EmailWhitelistAdd$EmailBlockReportDomain\?subject=add\%20to\%20whitelist&body=$1\%0D\%0A" title="add this email address to whitelist" target="_blank">$1<\/a>&nbsp;<a href="$prot:\/\/$host:$webAdminPort\/addraction?address=$1&showlogout=1" target="_blank" title="take an action via web on address $1">\@<\/a>/go
                      if (! $faddress && $is_admin);
                    $line =~ s/\[spam found\](\s*\(.*?\))( \Q$subjectStart\E)/<span name="tohid"><br \/><span class="spam">spam reason: <\/span>$1<\/span>$2/;
                    $line =~ s/($SpamTagRE|\[(?:TLS-(?:in|out)|SSL-(?:in|out)|PersonalBlack)\])/<span name="tohid">$1<\/span>/gio;
                    my $leftbut = '<a href="mailto:'.$EmailBlockReport.$EmailBlockReportDomain.'?subject=request%20SPAMBOX%20to%20resend%20blocked%20mail%20from%20SPAMBOX-host%20'.$myName.'&body=%23%23%23'.$filename.'%23%23%23'.$addWhiteHint.$addFileHint.'%0D%0A" class="reqlink" target="_blank" title="request SPAMBOX on '.$myName.' to resend this blocked email"><img src=cid:1000 alt="request SPAMBOX on '.$myName.' to resend this blocked email"> Resend </a>';
                    my $rightbut = '<a href="mailto:'.$ofilename.$EmailBlockReportDomain.'?&subject=request%20SPAMBOX%20to%20resend%20blocked%20mail%20from%20SPAMBOX-host%20'.$myName.'" class="reqlink" target="_blank" title="request SPAMBOX on '.$myName.' to resend this blocked email"><img src=cid:1000 alt="request SPAMBOX on '.$myName.' to resend this blocked email"> Resend </a>';
                    $rightbut = '' if (&matchSL(\@to,'BlockResendLinkLeft') or
                                             ($BlockResendLink == 1 && ! matchSL(\@to,'BlockResendLinkRight')));
                    $leftbut = '' if (&matchSL(\@to,'BlockResendLinkRight') or
                                             ($BlockResendLink == 2 && ! matchSL(\@to,'BlockResendLinkLeft')));
                    $line =~ s/^(.+\)\s*)(\Q$subjectStart\E.+?\Q$subjectEnd\E.*)$/$1<br\/><strong>$2<\/strong>/ unless $faddress;
                    $line =~ s/(.*)/\n<tr$bgcolor>\n<td class="leftlink">$leftbut\n<\/td>\n<td class="inner">$1\n<\/td>\n<td class="rightlink">$rightbut\n<\/td>\n<\/tr>/o;
                    push( @{ $buser->{ lc($address) }{html} }, $line);
                } else {
                    $line =~ s/\[spam found\](\s*\(.*?\))( \Q$subjectStart\E)/<span name="tohid"><br \/><span class="spam">spam reason: <\/span>$1<\/span>$2/;
                    $line =~ s/($SpamTagRE|\[(?:TLS-(?:in|out)|SSL-(?:in|out)|PersonalBlack)\])/<span name="tohid">$1<\/span>/gio;
                    $line =~
s/(\[OIP: )?($IPRe)(\])?/my($p1,$e,$p2)=($1,$2,$3);($e!~$IPprivate)?"<span name=\"tohid\" class=\"ip\"><a href=\"$prot:\/\/$host:$webAdminPort\/ipaction?ip=$e\&showlogout=1\" target=\"_blank\" title=\"take an action via web on ip $e\">$p1$e$p2<\/a><\/span>":"<span name=\"tohid\">$p1$e$p2<\/span>";/goe if $is_admin;
                    $line =~
s/($EmailAdrRe\@$EmailDomainRe)/<a href="mailto:$EmailWhitelistAdd$EmailBlockReportDomain\?subject=add\%20to\%20whitelist&body=$1\%0D\%0A" title="add this email address to whitelist" target="_blank">$1<\/a>/go
                      if (! $faddress && ! $is_admin);
                    $line =~
s/($EmailAdrRe\@$EmailDomainRe)/<a href="mailto:$EmailWhitelistAdd$EmailBlockReportDomain\?subject=add\%20to\%20whitelist&body=$1\%0D\%0A" title="add this email address to whitelist" target="_blank">$1<\/a>&nbsp;<a href="$prot:\/\/$host:$webAdminPort\/addraction?address=$1&showlogout=1" target="_blank" title="take an action via web on address $1">\@<\/a>/go
                      if (! $faddress && $is_admin);
                    $line =~ s/^(.+\)\s*)(\Q$subjectStart\E.+?\Q$subjectEnd\E.*)$/$1<br\/><strong>$2<\/strong>/ unless $faddress;
                    $line =~ s/(.*)/\n<tr$bgcolor>\n<td class="leftlink">&nbsp;\n<\/td>\n<td class="inner">$1\n<\/td>\n<td class="rightlink">&nbsp;\n<\/td>\n<\/tr>/o;
                    push( @{ $buser->{ lc($address) }{html} }, $line );
                }
            } else {
                push( @{ $buser->{ lc($address) }{text} }, "\r\n$fl\r\n");
                $line =~ s/\[spam found\](\s*\(.*?\))( \Q$subjectStart\E)/<span name="tohid"><br \/><span class="spam">spam reason: <\/span>$1<\/span>$2/;
                $line =~ s/($SpamTagRE|\[(?:TLS-(?:in|out)|SSL-(?:in|out)|PersonalBlack)\])/<span name="tohid">$1<\/span>/gio;
                $line =~
s/(\[OIP: )?($IPRe)(\])?/my($p1,$e,$p2)=($1,$2,$3);($e!~$IPprivate)?"<span name=\"tohid\" class=\"ip\"><a href=\"$prot:\/\/$host:$webAdminPort\/ipaction?ip=$e\&showlogout=1\" target=\"_blank\" title=\"take an action via web on ip $e\">$p1$e$p2<\/a><\/span>":"<span name=\"tohid\">$p1$e$p2<\/span>";/goe if $is_admin;
                $line =~
s/($EmailAdrRe\@$EmailDomainRe)/<a href="mailto:$EmailWhitelistAdd$EmailBlockReportDomain\?subject=add\%20to\%20whitelist&body=$1\%0D\%0A" title="add this email address to whitelist" target="_blank">$1<\/a>/go
                  if (! $faddress && ! $is_admin);
                $line =~
s/($EmailAdrRe\@$EmailDomainRe)/<a href="mailto:$EmailWhitelistAdd$EmailBlockReportDomain\?subject=add\%20to\%20whitelist&body=$1\%0D\%0A" title="add this email address to whitelist" target="_blank">$1<\/a>&nbsp;<a href="$prot:\/\/$host:$webAdminPort\/addraction?address=$1&showlogout=1" target="_blank" title="take an action via web on address $1">\@<\/a>/go
                  if (! $faddress && $is_admin);
                $line =~ s/^(.+\)\s*)(\Q$subjectStart\E.+?\Q$subjectEnd\E.*)$/$1<br\/><strong>$2<\/strong>/ unless $faddress;
                $line =~ s/(.*)/\n<tr$bgcolor>\n<td class="leftlink">&nbsp;\n<\/td>\n<td class="inner">$1\n<\/td>\n<td class="rightlink">&nbsp;\n<\/td>\n<\/tr>/o;
                push( @{ $buser->{ lc($address) }{html} }, $line );
            }
        }
        close $FLogFile;
    }
    while ( my ($ad,$v) = each %$buser ) {
        next if ( $ad eq 'sum' );
        push( @{ $buser->{$ad}{html} }, "\n</table>\n<br />\n");
        delete $buser->{$ad}{bgcolor};
        if (exists $buser->{$ad}{filtercount}) {
            push( @{ $buser->{$ad}{html} },"<br />\n".$buser->{$ad}{filter}."<br />\n");
            push( @{ $buser->{$ad}{text} },"\r\n\r\n".$buser->{$ad}{filter}."\r\n");
            $buser->{$ad}{correct}--;
        }
        if (exists $buser->{$ad}{filtercount2}) {
            push( @{ $buser->{$ad}{html} },"<br />\n") unless exists $buser->{$ad}{filtercount};
            push( @{ $buser->{$ad}{html} },$buser->{$ad}{filter2}."<br />\n");
            push( @{ $buser->{$ad}{text} },"\r\n\r\n") && $buser->{$ad}{correct}-- unless exists $buser->{$ad}{filtercount};
            push( @{ $buser->{$ad}{text} },$buser->{$ad}{filter2}."\r\n");
            $buser->{$ad}{correct}--;
        }
        delete $buser->{$ad}{filter};
        delete $buser->{$ad}{filtercount};
        delete $buser->{$ad}{filter2};
        delete $buser->{$ad}{filtercount2};
    }
    $bytes                    = formatDataSize( $bytes, 1 );
    $runtime                  = time - $runtime;
    $buser->{sum}{mimehead}     = $mimehead;
    $buser->{sum}{mimebot}      = $mimebot;
    $buser->{sum}{textparthead} = $textparthead;
    $buser->{sum}{htmlparthead} = $htmlparthead;
    $buser->{sum}{htmlhead}     = $htmlhead;

    $buser->{sum}{html} .= "\n".($enableBRtoggleButton ? <<'EOT1' : <<'EOT2');
<input type="button" name="toggle" value="toggle view" onclick="show=((show=='none')?'inline':'none');changeview(show);return false;"
 title="click the button to simplify or to extend the BlockReport view - requires javascript to be enabled in your mail clients HTML view">
<br />
EOT1
<br />
EOT2
    my ($t10html,$t10text);
    if ($DoT10Stat && $isadmin == 1) {
        ($t10html,$t10text) = T10StatOut();
        my $ire = qr/^(?:$IPRe|[\d\.]+)$/o;
        $t10html =~ s/((?:$EmailAdrRe\@)?$EmailDomainRe)/my$e=$1;($e!~$ire)?"<a href=\"$prot:\/\/$host:$webAdminPort\/addraction?address=$e\&showlogout=1\" target=\"_blank\" title=\"take an action via web on address $e\">$e<\/a>":$e/goe;
        $t10html =~ s/($IPRe)/my$e=$1;($e!~$IPprivate)?"<a href=\"$prot:\/\/$host:$webAdminPort\/ipaction?ip=$e\&showlogout=1\" target=\"_blank\" title=\"take an action via web on ip $e\">$e<\/a>":$e;/goe;
    }
    if (   matchSL( $this->{mailfrom}, 'EmailAdmins', 1 )
        or matchSL( $this->{mailfrom}, 'BlockReportAdmins', 1 )
        or lc( $this->{mailfrom} ) eq lc($EmailAdminReportsTo)
        or lc( $this->{mailfrom} ) eq lc($EmailBlockTo) )
    {
        $buser->{sum}{html} .= $t10html . "<br />\n<div name=\"tohid\">" . &needEs($lines, ' line','s') . " with $bytes analysed in " .
            &needEs($numfiles,' logfile','s') . " on host $myName in $runtime seconds - running SPAMBOX version $MAINVERSION<br /></div>\n";
        $buser->{sum}{text} .= $t10text . "\r\n\r\n" . &needEs($lines, ' line','s') . " with $bytes analysed in " .
            &needEs($numfiles,' logfile','s') . " on host $myName in $runtime seconds - running SPAMBOX version $MAINVERSION\r\n";
    } else {
        $buser->{sum}{html} .= "\n".($enableBRtoggleButton ? <<'EOT' : '');
<script type="text/javascript">
<!--
show = "none";
changeview(show);
// -->
</script>
EOT
    }
    $buser->{sum}{html} .= "</body>\n</html>\n";
    return;
}
