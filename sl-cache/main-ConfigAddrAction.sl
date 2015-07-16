#line 1 "sub main::ConfigAddrAction"
package main; sub ConfigAddrAction {
    my $addr = lc($qs{address});
    my $run = $qs{address};
    $addr =~ s/^\s+//o;
    $addr =~ s/\s+$//o;
    my $local;
    my $isnameonly;
    my $wlfrm;
    my $wlto;
    $local = localmail($addr) if $addr;
    my $action = $qs{action};
    my $slo;
    $slo = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button"  name="showlogout" value="  logout " onclick="window.location.href=\'./logout\';return false;"/></span>' if exists $qs{showlogout};
    my $s = $qs{reloaded} eq 'reloaded' ? '<span class="positive">(page was auto reloaded)</span><br /><br />' : '';

    my $mfd;my $wrongaddr;
    if ($addr =~ /^((?:$EmailAdrRe)?(\@$EmailDomainRe))(?:,($EmailAdrRe?\@$EmailDomainRe))?$/io) {
        $wlfrm = $1;
        $mfd = $2;
        $wlto = $3;
    } elsif ($addr =~ /^($EmailDomainRe)$/io) {
        $mfd = $1;
    } elsif ($addr =~ /^$EmailAdrRe$/io) {
        $isnameonly = '<br />This is interpreted as the userpart of an email address!<br />';
    } else {
        $wrongaddr = '<br /><span class="negative">This is not a valid email address or domain!</span><br />';
    }
    
    if ($addr && $action && $qs{Submit} && !$wrongaddr) {
        my %lqs = %qs;
        if ($mfd && $action eq '1' && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists')) {
            %qs = ('action' => 'a', 'list' => 'white', 'addresses' => $addr);
            $s = &ConfigLists();
            $s =~ s/^.+?<\/h2>(.+?)<form.+$/$1/ois;
        } elsif ($mfd && $action eq '2' && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists')) {
            %qs = ('action' => 'r', 'list' => 'white', 'addresses' => $addr);
            $s = &ConfigLists();
            $s =~ s/^.+?<\/h2>(.+?)<form.+$/$1/ois;
        } elsif ($mfd && $action eq '3' && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists')) {
            %qs = ('action' => 'a', 'list' => 'red', 'addresses' => $addr);
            $s = &ConfigLists();
            $s =~ s/^.+?<\/h2>(.+?)<form.+$/$1/ois;
        } elsif ($mfd && $action eq '4' && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists')) {
            %qs = ('action' => 'r', 'list' => 'red', 'addresses' => $addr);
            $s = &ConfigLists();
            $s =~ s/^.+?<\/h2>(.+?)<form.+$/$1/ois;
        } elsif ($action eq '5' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessing')) {
            my $r = $GPBmodTestList->('GUI','noProcessing','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to noProcessing" : "$addr not added to noProcessing";
        } elsif ($action eq '6' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessing')) {
            my $r = $GPBmodTestList->('GUI','noProcessing','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from noProcessing" : "$addr not removed from noProcessing";
        } elsif ($action eq '7' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingFrom')) {
            my $r = $GPBmodTestList->('GUI','noProcessingFrom','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to noProcessingFrom" : "$addr not added to noProcessingFrom";
        } elsif ($action eq '8' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingFrom')) {
            my $r = $GPBmodTestList->('GUI','noProcessingFrom','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from noProcessingFrom" : "$addr not removed from noProcessingFrom";
        } elsif ($mfd && $action eq '9' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedDomains')) {
            my $r = $GPBmodTestList->('GUI','whiteListedDomains','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to whiteListedDomains" : "$addr not added to whiteListedDomains";
        } elsif ($mfd && $action eq 'A' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedDomains')) {
            my $r = $GPBmodTestList->('GUI','whiteListedDomains','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from whiteListedDomains" : "$addr not removed from whiteListedDomains";
        } elsif ($mfd && $action eq 'B' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','blackListedDomains')) {
            my $r = $GPBmodTestList->('GUI','blackListedDomains','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to blackListedDomains" : "$addr not added to blackListedDomains";
        } elsif ($mfd && $action eq 'C' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','blackListedDomains')) {
            my $r = $GPBmodTestList->('GUI','blackListedDomains','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from blackListedDomains" : "$addr not removed from blackListedDomains";
        } elsif ($action eq 'D' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamLovers')) {
            my $r = $GPBmodTestList->('GUI','spamLovers','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to spamLovers (All Spam-Lover)" : "$addr not added to spamLovers (All Spam-Lover)";
        } elsif ($action eq 'E' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamLovers')) {
            my $r = $GPBmodTestList->('GUI','spamLovers','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from spamLovers (All Spam-Lover)" : "$addr not removed from spamLovers (All Spam-Lover)";
        } elsif ($action eq 'F' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamHaters')) {
            my $r = $GPBmodTestList->('GUI','spamHaters','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to spamHaters (All Spam-Haters)" : "$addr not added to spamHaters (All Spam-Haters)";
        } elsif ($action eq 'G' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamHaters')) {
            my $r = $GPBmodTestList->('GUI','spamHaters','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from spamHaters (All Spam-Haters)" : "$addr not removed from spamHaters (All Spam-Haters)";
        } elsif ($mfd && $action eq 'H' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingDomains')) {
            my $r = $GPBmodTestList->('GUI','noProcessingDomains','add',' - via MaillogTail',$mfd,0);
            $s = ($r > 0) ? "$mfd added to noProcessing Domains" : "$mfd not added to noProcessing Domains";
        } elsif ($mfd && $action eq 'I' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingDomains')) {
            my $r = $GPBmodTestList->('GUI','noProcessingDomains','delete',' - via MaillogTail',$mfd,0);
            $s = ($r > 0) ? "$mfd removed from noProcessing Domains" : "$mfd not removed from noProcessing Domains";
        } elsif ($action eq 'J' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','preHeaderRe')) {
            my $addrRe = quotemeta($addr);
            my $r = $GPBmodTestList->('GUI','preHeaderRe','add',' - via MaillogTail',$addrRe,0);
            $s = ($r > 0) ? "$addr added as regex ($addrRe) to preHeaderRe" : "$addr not added to preHeaderRe";
        } elsif ($action eq 'K' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','preHeaderRe')) {
            my $addrRe = quotemeta($addr);
            my $r = $GPBmodTestList->('GUI','preHeaderRe','delete',' - via MaillogTail',$addrRe,0);
            $s = ($r > 0) ? "$addr removed as regex ($addrRe) from preHeaderRe" : "$addr not removed from preHeaderRe";
        } elsif ($action eq 'L' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScan')) {
            my $r = $GPBmodTestList->('GUI','noScan','add',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr added to sDo Not Virus-Scan Messages from/to these Addresses(noScan)" : "$addr not added to Do Not Scan Messages from/to these Addresses(noScan)";
        } elsif ($action eq 'M' && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScan')) {
            my $r = $GPBmodTestList->('GUI','noScan','delete',' - via MaillogTail',$addr,0);
            $s = ($r > 0) ? "$addr removed from Do Not Virus-Scan Messages from/to these Addresses(noScan)" : "$addr not Do Not Scan Messages from/to these Addresses(noScan)";
        } elsif ($action) {
            $s = "<span class=\"negative\">access denied for the selected action</span>";
        }
        %qs = %lqs;
    }
    $s = 'no action selected - or no result available' if (! $s && $qs{Submit});
    if ($s !~ /not|negative/ && $qs{Submit}) {
        $ConfigChanged = 1;
        &tellThreadsReReadConfig();   # reread the config
    }

    my $option  = "<option value=\"0\">select action</option>";
    if ($addr && ! $wrongaddr) {
        $option .= "<option value=\"1\">add to WhiteList</option>"
         if ($mfd && ! $local && ! Whitelist($wlfrm,$wlto,'') && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists'));
        $option .= "<option value=\"2\">remove from WhiteList</option>"
         if ($mfd && ! $local &&  Whitelist($wlfrm,$wlto,'') && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists'));
        $option .= "<option value=\"3\">add to RedList</option>"
         if ($mfd && ! exists $Redlist{$addr} && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists'));
        $option .= "<option value=\"4\">remove from RedList</option>"
         if ($mfd && exists $Redlist{$addr} && &canUserDo($WebIP{$ActWebSess}->{user},'action','lists'));
        $option .= "<option value=\"5\">add to noProcessing addresses</option>"
         if ($noProcessing=~/\s*file\s*:\s*.+/o && ! $local && ! matchSL( $addr, 'noProcessing' ,1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessing'));
        $option .= "<option value=\"6\">remove from noProcessing addresses</option>"
         if ($noProcessing=~/\s*file\s*:\s*.+/o && ! $local &&  matchSL( $addr, 'noProcessing' ,1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessing'));
        $option .= "<option value=\"7\">add to noProcessingFrom addresses</option>"
         if ($noProcessingFrom=~/\s*file\s*:\s*.+/o && ! $local && ! matchSL( $addr, 'noProcessingFrom' ,1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingFrom'));
        $option .= "<option value=\"8\">remove from noProcessingFrom addresses</option>"
         if ($noProcessingFrom=~/\s*file\s*:\s*.+/o && ! $local && matchSL( $addr, 'noProcessingFrom' ,1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingFrom'));
        $option .= "<option value=\"9\">add to whitelisted domains/addresses</option>"
         if ($mfd && $whiteListedDomains=~/\s*file\s*:\s*.+/o && ! $local && ! matchRE([$addr],'whiteListedDomains',1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedDomains'));
        $option .= "<option value=\"A\">remove from whitelisted domains/addresses</option>"
         if ($mfd && $whiteListedDomains=~/\s*file\s*:\s*.+/o && ! $local && matchRE([$addr],'whiteListedDomains',1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','whiteListedDomains'));
        $option .= "<option value=\"B\">add to blacklisted domains/addresses</option>"
         if ($mfd && $blackListedDomains=~/\s*file\s*:\s*.+/o && ! $local && ! matchRE([$addr],'blackListedDomains',1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','blackListedDomains'));
        $option .= "<option value=\"C\">remove from blacklisted domains/addresses</option>"
         if ($mfd && $blackListedDomains=~/\s*file\s*:\s*.+/o && ! $local && matchRE([$addr],'blackListedDomains',1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','blackListedDomains'));
        $option .= "<option value=\"D\">add to All Spam-Lover</option>"
         if ($spamLovers=~/\s*file\s*:\s*.+/o && $local && $addr !~ /$SLRE/ && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamLovers'));
        $option .= "<option value=\"E\">remove from All Spam-Lover</option>"
         if ($spamLovers=~/\s*file\s*:\s*.+/o && $local && $addr =~ /$SLRE/ && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamLovers'));
        $option .= "<option value=\"F\">add to All Spam-Haters</option>"
         if ($spamHaters=~/\s*file\s*:\s*.+/o && $local && $addr !~ /$SHRE/ && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamHaters'));
        $option .= "<option value=\"G\">remove from All Spam-Haters</option>"
         if ($spamHaters=~/\s*file\s*:\s*.+/o && $local && $addr =~ /$SHRE/ && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','spamHaters'));
        $option .= "<option value=\"H\">add $mfd to noProcessing domains</option>"
         if ($mfd && $noProcessingDomains=~/\s*file\s*:\s*.+/o && ! $local && $mfd !~ /$NPDRE/ && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingDomains'));
        $option .= "<option value=\"I\">remove $mfd from noProcessing domains</option>"
         if ($mfd && $noProcessingDomains=~/\s*file\s*:\s*.+/o  && ! $local && $mfd =~ /$NPDRE/ && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noProcessingDomains'));

#experimental for preHeaderRe
        my $addrRe = quotemeta($addr);
        $option .= "<option value=\"J\">add to preHeaderRe as regex</option>"
         if ($preHeaderRe=~/\s*file\s*:\s*.+/o && ! $local && $GPBmodTestList->('GUI','preHeaderRe','check','',$addrRe,0) != 2 && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','preHeaderRe'));
        $option .= "<option value=\"K\">remove regex from preHeaderRe</option>"
         if ($preHeaderRe=~/\s*file\s*:\s*.+/o && ! $local && $GPBmodTestList->('GUI','preHeaderRe','check','',$addrRe,0) == 2 && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','preHeaderRe'));
#end experimental for preHeaderRe

        $option .= "<option value=\"L\">add to no Virus-Scan addresses</option>"
         if ($noScan=~/\s*file\s*:\s*.+/o && ! $local && ! matchSL( $addr, 'noScan' ,1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScan'));
        $option .= "<option value=\"M\">remove from no Virus-Scan addresses</option>"
         if ($noScan=~/\s*file\s*:\s*.+/o && ! $local &&  matchSL( $addr, 'noScan' ,1) && &canUserDo($WebIP{$ActWebSess}->{user},'cfg','noScan'));
    }

    if ($addr && ! $wrongaddr) {
        my @ad = ($addr);
        push @ad , $mfd if $mfd && $mfd ne $addr;
        $s .= "<br /><br /><b>general address-matches for $addr :</b><br /><br />\n";
        foreach (sort {lc($main::a) cmp lc($main::b)} keys %MakeSLRE) {
            next unless ${$_};
            my $reRE = ${$MakeSLRE{$_}};
            next if $reRE =~ /$neverMatchRE/o;
            next unless &canUserDo($WebIP{$ActWebSess}->{user},'cfg',$_);
            my $r = matchARRAY($reRE,\@ad);
            $s .= "matches in<b> $_ </b>with <b>$r</b><br />" if $r;
        }
        foreach (sort {lc($main::a) cmp lc($main::b)} keys %preMakeRE) {
            next if $preMakeRE{$_} == 1;
            next unless ${$preMakeRE{$_}};
            next if ${$_} =~ /$neverMatchRE/o;
            next unless &canUserDo($WebIP{$ActWebSess}->{user},'cfg',$preMakeRE{$_});
            my $r = matchARRAY(${$_},\@ad);
            $s .= "matches in<b> $preMakeRE{$_} </b>with <b>$r</b><br />" if $r;
        }
    }

    if ($WebIP{$ActWebSess}->{user} eq 'root' && $run =~ s/^\s*([\$\%\@\&][^\n]+|\d{10}$)/$1/o) {
        $addr = $run;
        my $ret = "eval result for $run :<br /><br />";
        my $res;
        my $orun = $run;
        if ($run =~ /^\&/o) {
            my ($sub,$parm) = parseEval($run);
            if ($sub) {
                mlog(0,"info: executing command '$run' ");
                if (lc($sub) eq 'runeval' or lc($sub) eq '&runeval') {
                    $res = &RunEval($parm);
                } else {
                    $sub =~ s/^\&//o;
                    $res = eval{$sub->(split(/\,/o,$parm));};
                }
            }
        } elsif ($run =~ s/^\$//o && defined ${$run}) {
            $res = ${$run};
        } elsif ($run =~ s/^\%//o && eval('defined %{$run};')) {
            $res .= "'$_' => '".${$run}{$_}.'\'<br />' foreach (sort keys %{$run});
        } elsif ($run =~ s/^\@//o && eval('defined @{$run};')) {
            $res = join('<br />', @{$run});
        } elsif ($run =~ /^\d{10}$/o) {
            $res = $run;
        } else {
            $res = "'$orun' is not defined";
        }
        $res .= ' , ' . timestring($res) if $res =~ /^\d{10}$/o;
        $s .= $ret . $res;
    }

    return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage SPAMBOX address action ($myName)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
</head>
<body onmouseover="this.focus();" ondblclick="this.select();">
<h2>add/remove addresses from lists</h2><hr>
    <div class="content">
      <form name="edit" id="edit" action="" method="post" autocomplete="off">
        <h3>address to work with</h3>
        <input name="address" size="100" autocomplete="off" value="$addr" onchange="document.forms['edit'].action.value='0';document.forms['edit'].reloaded.value='reloaded';document.forms['edit'].submit();return false;"/>
        $wrongaddr$isnameonly
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
      <br />Only configured (file:...), possible and authorized option are shown.
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
