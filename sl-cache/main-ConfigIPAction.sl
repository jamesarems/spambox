#line 1 "sub main::ConfigIPAction"
package main; sub ConfigIPAction {
    my $addr = lc($qs{ip});
    $addr =~ s/^\s+//o;
    $addr =~ s/\s+$//o;
    my $wrongaddr;
    if ($addr !~ /^$IPRe$/o) {
        $wrongaddr = '<br /><span class="negative">This is not a valid IP address or a resolvable hostname!</span><br />' ;
    }
    if ($wrongaddr && $addr =~ /^$HostRe$/o) {
        my $ta = $addr;
        $addr = join(' ' ,&getRRA($ta,''));
        if ($addr =~ /($IPv4Re)/o) {
            $addr = $1;
        } elsif ($addr =~ /($IPv6Re)/o) {
            $addr = $1;
        } else {
            $addr = undef;
        }
        eval {$addr = inet_ntoa( scalar( gethostbyname($ta) ) );} unless $addr;
        if ($addr =~ /^$IPRe$/o ) {
            $wrongaddr = undef;
        } else {
            $addr = $ta;
        }
    }
    my $local = $addr =~ /^$IPprivate$/o || $addr eq $localhostip || $addr =~ /$LHNRE/;
    my $action = $qs{action};
    my $slo;
    $slo = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button"  name="showlogout" value="  logout " onclick="window.location.href=\'./logout\';return false;"/></span>' if exists $qs{showlogout};
    my $s = $qs{reloaded} eq 'reloaded' ? '<span class="positive">(page was auto reloaded)</span><br /><br />' : '';

    if ($addr && $action && $qs{Submit} && ! $wrongaddr) {
        if ($action eq '1' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingIPs')) {
            my $r = $GPBmodTestList->('GUI','noProcessingIPs','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to noProcessingIPs" : "$addr not added to noProcessingIPs";
        } elsif ($action eq '2' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingIPs')) {
            my $r = $GPBmodTestList->('GUI','noProcessingIPs','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from noProcessingIPs" : "$addr not removed from noProcessingIPs";
        } elsif ($action eq '3' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedIPs')) {
            my $r = $GPBmodTestList->('GUI','whiteListedIPs','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to whiteListedIPs" : "$addr not added to whiteListedIPs";
        } elsif ($action eq '4' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedIPs')) {
            my $r = $GPBmodTestList->('GUI','whiteListedIPs','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from whiteListedIPs" : "$addr not removed from whiteListedIPs";
        } elsif ($action eq '5' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noDelay')) {
            my $r = $GPBmodTestList->('GUI','noDelay','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to noDelay" : "$addr not added to noDelay";
        } elsif ($action eq '6' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noDelay')) {
            my $r = $GPBmodTestList->('GUI','noDelay','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from noDelay" : "$addr not removed from noDelay";
        } elsif ($action eq '7' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFrom')) {
            my $r = $GPBmodTestList->('GUI','denySMTPConnectionsFrom','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to denySMTPConnectionsFrom" : "$addr not added to denySMTPConnectionsFrom";
        } elsif ($action eq '8' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFrom')) {
            my $r = $GPBmodTestList->('GUI','denySMTPConnectionsFrom','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from denySMTPConnectionsFrom" : "$addr not removed from denySMTPConnectionsFrom";
        } elsif ($action eq '9' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noBlockingIPs')) {
            my $r = $GPBmodTestList->('GUI','noBlockingIPs','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to noBlockingIPs" : "$addr not added to noBlockingIPs";
        } elsif ($action eq 'A' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noBlockingIPs')) {
            my $r = $GPBmodTestList->('GUI','noBlockingIPs','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from noBlockingIPs" : "$addr not removed from noBlockingIPs";
        } elsif ($action eq 'B' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFromAlways')) {
            my $r = $GPBmodTestList->('GUI','denySMTPConnectionsFromAlways','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to denySMTPConnectionsFromAlways" : "$addr not added to denySMTPConnectionsFromAlways";
        } elsif ($action eq 'C' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFromAlways')) {
            my $r = $GPBmodTestList->('GUI','denySMTPConnectionsFromAlways','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from denySMTPConnectionsFromAlways" : "$addr not removed from denySMTPConnectionsFromAlways";
        } elsif ($action eq 'D' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            my $t = time;
            my $data="$t $t 2 manually_added";
            my $ip=&ipNetwork($addr,1);
            $PBWhite{$ip}=$data;
            $PBWhite{$addr}=$data;
            $s = "$addr added to PenaltyBox white" ;
        } elsif ($action eq 'E' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            &pbWhiteDelete(0,$addr);
            $s = "$addr removed from PenaltyBox white" ;
        } elsif ($action eq 'F' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            my $ip=&ipNetwork($addr, $PenaltyUseNetblocks );
            delete $PBBlack{$ip};
            delete $PBBlack{$addr};
            $s = "$addr removed from PenaltyBox black";
        } elsif ($action eq 'G' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            delete $PTRCache{$addr};
            $s = "$addr removed from PTR Cache";
        } elsif ($action eq 'H' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            delete $URIBLCache{$addr};
            $s = "$addr removed from URIBL Cache";
        } elsif ($action eq 'I' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            my @record = SBCacheFind($addr);
            my $domain = [split( /\|/o, $record[2])]->[2];
            delete $WhiteOrgList{lc $domain} if $domain;
            delete $SBCache{$record[0]};
            $s = "$record[0] removed from SenderBase Cache";
        } elsif ($action eq 'J' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            delete $RBLCache{$addr};
            $s = "$addr removed from RBL Cache";
        } elsif ($action eq 'K' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            delete $MXACache{$addr};
            $s = "$addr removed from MXA Cache";
        } elsif ($action eq 'L' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            delete $BackDNS{$addr};
            delete $BackDNS2{$addr};
            $s = "$addr removed from Backscatter Cache";
        } elsif ($action eq 'M' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb')) {
            delete $RWLCache{$addr};
            $s = "$addr removed from RWL Cache";
        } elsif ($action eq 'N' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScanIP')) {
            my $r = $GPBmodTestList->('GUI','noScanIP','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to Virus-noScanIP" : "$addr not added to Virus-noScanIP";
        } elsif ($action eq 'O' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScanIP')) {
            my $r = $GPBmodTestList->('GUI','noScanIP','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from Virus-noScanIP" : "$addr not removed from Virus-noScanIP";
        } elsif ($action) {
            $s = "<span class=\"negative\">access denied for the selected action</span>";
        }
    }
    $s = 'no action selected - or no result available' if (! $s && $qs{Submit});

    if ($s =~ /\Q$addr\E (?:added to|removed from)/ && $qs{Submit}) {
        $ConfigChanged = 1;
        &tellThreadsReReadConfig();   # reread the config
    }

    my $option  = "<option value=\"0\">select action</option>";
    if ($addr && ! $wrongaddr) {
        $option .= "<option value=\"1\">add to noProcessing IP's</option>"
         if (! $local && $noProcessingIPs=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'noProcessingIPs',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingIPs'));
        $option .= "<option value=\"2\">remove from noProcessing IP's</option>"
         if (! $local && $noProcessingIPs=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'noProcessingIPs',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingIPs'));
        $option .= "<option value=\"3\">add to whitelisted IP's</option>"
         if (! $local && $whiteListedIPs=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'whiteListedIPs',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedIPs'));
        $option .= "<option value=\"4\">remove from whitelisted IP's</option>"
         if (! $local && $whiteListedIPs=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'whiteListedIPs',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedIPs'));
        $option .= "<option value=\"5\">add to noDelay IP's</option>"
         if (! $local && $noDelay=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'noDelay',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noDelay'));
        $option .= "<option value=\"6\">remove from noDelay IP's</option>"
         if (! $local && $noDelay=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'noDelay',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noDelay'));
        $option .= "<option value=\"7\">add to Deny Connections from these IP's</option>"
         if (! $local && $denySMTPConnectionsFrom=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'denySMTPConnectionsFrom',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFrom'));
        $option .= "<option value=\"8\">remove from Deny Connections from these IP's</option>"
         if (! $local && $denySMTPConnectionsFrom=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'denySMTPConnectionsFrom',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFrom'));
        $option .= "<option value=\"9\">add to Do not block Connections from these IP's</option>"
         if (! $local && $noBlockingIPs=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'noBlockingIPs',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noBlockingIPs'));
        $option .= "<option value=\"A\">remove from Do not block Connections from these IP's</option>"
         if (! $local && $noBlockingIPs=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'noBlockingIPs',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noBlockingIPs'));
        $option .= "<option value=\"B\">add to Deny Connections from these IP's Strictly</option>"
         if (! $local && $denySMTPConnectionsFromAlways=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'denySMTPConnectionsFromAlways',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFromAlways'));
        $option .= "<option value=\"C\">remove from Deny Connections from these IP's Strictly</option>"
         if (! $local && $denySMTPConnectionsFromAlways=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'denySMTPConnectionsFromAlways',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','denySMTPConnectionsFromAlways'));
        $option .= "<option value=\"D\">add to PenaltyBox white</option>"
         if (! &pbWhiteFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"E\">remove from PenaltyBox white</option>"
         if (&pbWhiteFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"F\">remove from PenaltyBox black</option>"
         if (&pbBlackFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"G\">remove from PTR Cache</option>"
         if (defined &PTRCacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"H\">remove from URIBL Cache</option>"
         if (&URIBLCacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"I\">remove from SenderBase Cache</option>"
         if (&SBCacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"J\">remove from RBL Cache</option>"
         if (&RBLCacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"K\">remove from MXA Cache</option>"
         if (&MXACacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"L\">remove from Backscatter Cache</option>"
         if (&BackDNSCacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"M\">remove from RWL Cache</option>"
         if (&RWLCacheFind($addr) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','pbdb'));
        $option .= "<option value=\"N\">add to Do Not Virus-Scan Messages from these IP\'s</option>"
         if ($noScanIP=~/\s*file\s*:\s*.+/o && ! matchIP( $addr, 'noScanIP',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScanIP'));
        $option .= "<option value=\"O\">remove from Do Not Virus-Scan Messages from these IP\'s</option>"
         if ($noScanIP=~/\s*file\s*:\s*.+/o &&  matchIP( $addr, 'noScanIP',0,1 ) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScanIP'));
    }

    if ($addr && ! $wrongaddr) {
        $s .= "<br /><br /><b>general IP-matches for $addr :</b><br /><br />\n";
        foreach (sort {lc($main::a) cmp lc($main::b)} keys %MakeIPRE) {
            next unless &canUserDo($WebIP{$ActWebSess}->{user},'cfg',$_);
            my $res = matchIP( $addr, $_,0,1 );
            $s .= "matches in<b> $_ </b>with <b>$res</b><br />" if $res;
        }
    }

    return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage SPAMBOX IP action ($myName)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
</head>
<body onmouseover="this.focus();" ondblclick="this.select();">
<h2>add/remove IP addresses from lists</h2><hr>
    <div class="content">
      <form name="edit" id="edit" action="" method="post" autocomplete="off">
        <h3>IP-address or hostname to work with</h3>
        <input name="ip" size="20" autocomplete="off" value="$addr" onchange="document.forms['edit'].action.value='0';document.forms['edit'].reloaded.value='reloaded';document.forms['edit'].submit();return false;"/>
        $wrongaddr
        <br /><hr>
        <div style="align: left">
         <div class="shadow">
          <div class="option">
           <div class="optionValue">
            <select size="1" name="action">
             $option
            </select>
           </div>
          </div>
         </div>
        </div>
        <hr>
        <input type="submit" name="Submit" value="Submit" />&nbsp;&nbsp;&nbsp;&nbsp;
        <input type="hidden" name="reloaded" value="" />
        <input type="button" value="Close" onclick="javascript:window.close();"/>
        $slo
        <hr>
      </form>
      <br />Only configured, possible and authorized option are shown.
      <hr>
      <div class="note" id="notebox">
        <h3>results for action</h3><hr>
        $s
      </div>
    </div>
</body>
</html>

EOT
}
