#line 1 "sub main::ConfigLists"
package main; sub ConfigLists {
    my $s;
    my $ad;
    my $v;
    my $act=$qs{action};
    if($act) {
        if ($qs{list} eq 'tuplets') {
            my $ip;
            my $hash;
            my $t;
            my $interval;
            my $intervalFormatted;
            while ($qs{addresses}=~/($IPRe)\s*,?\s*<?(?:$EmailAdrRe\@)?($EmailDomainRe|)>?/go) {
                $ip=&ipNetwork($1,$DelayUseNetblocks);
                $ad=lc $2;
                if ($DelayNormalizeVERPs) {

                    # strip extension
                    $ad=~s/\+.*(?=\@)//o;

                    # replace numbers with '#'
                    $ad=~s/\b\d+\b(?=.*\@)/#/go;
                }

                # get sender domain
                $ad=~s/[^@]*@//o;
                $hash="$ip $ad";
                $hash=Digest::MD5::md5_hex($hash) if $CanUseMD5Keys && $DelayMD5;
                $t=time;
                $s.="<div class=\"text\">($ip,$ad) ";
                if($act eq 'v') {
                    if (!exists $DelayWhite{$hash}) {
                        $s.="<span class=\"negative\">tuplet NOT safelisted</span>";
                    } else {
                        $interval=$t-$DelayWhite{$hash};
                        $intervalFormatted=formatTimeInterval($interval);
                        if ($interval<$DelayExpiryTime*24*3600) {
                            $s.="tuplet safelisted, age: $intervalFormatted";
                        } else {
                            $s.="tuplet expired, age: $intervalFormatted";
                        }
                    }
                } elsif($act eq 'a') {
                    if (!exists $DelayWhite{$hash} || ($t-$DelayWhite{$hash}>=$DelayExpiryTime*24*3600)) {
                        if(localmail('@'.$ad)) {
                            $s.="<span class=\"negative\">local addresses not allowed on safelisted tuplets</span>";
                        } else {
                            $s.="tuplet added";
                            $DelayWhite{$hash}=$t;
                            mlog(0,"Admininfo: safelisted tuplets addition: ($ip,$ad) (by $WebIP{$ActWebSess}->{user})",1);
                        }
                    } else {
                        $s.="<span class=\"positive\">tuplet already safelisted</span>";
                    }
                } elsif($act eq 'r') {
                    if (!exists $DelayWhite{$hash}) {
                        $s.="<span class=\"negative\">tuplet NOT safelisted</span>";
                    } else {
                        $interval=$t-$DelayWhite{$hash};
                        $intervalFormatted=formatTimeInterval($interval);
                        if ($interval<$DelayExpiryTime*24*3600) {
                            $s.="tuplet removed, age: $intervalFormatted";
                        } else {
                            $s.="expired tuplet removed, age: $intervalFormatted";
                        }
                        delete $DelayWhite{$hash};
                        mlog(0,"Admininfo: safelisted tuplets deletion: ($ip,$ad) (by $WebIP{$ActWebSess}->{user})");
                    }
                }
                $s.="</div>\n";
            }
        } elsif ($qs{list} eq 'red' or $qs{list} eq 'white') {
            my $color=$qs{list} eq 'red'? 'Red' : 'White';
            my $list=$color."list";
            while ($qs{addresses}=~/($EmailAdrRe\@$EmailDomainRe'?)(?:(,(?:$EmailAdrRe?\@$EmailDomainRe'?)|\*))?/go) {
                $ad=$1;
                my $ap = $2;
                $ad =~ s/^'//o if $ad =~ s/'$//o;
                $ap =~ s/^,'/,/o if $ap =~ s/'$//o;
                $s.="<div class=\"text\">$ad ";
                $ad=lc $ad;
                $ap=lc $ap;
                if($act eq 'v') {
                    $ap = '' if $ap eq ',*';
                    $ap = '' if ((!($WhitelistPrivacyLevel % 2)) && $ap =~ /^,\@/o);
                    if ($list eq 'Whitelist' && $ap) {
                        if($list->{"$ad$ap"}) {
                            $s.="$ap ${color}listed";
                        } else {
                            $s.="<span class=\"negative\">$ap NOT $qs{list}listed</span>";
                        }
                    } elsif ($list eq 'Whitelist' && ! $ap) {
                        if($list->{$ad}) {
                            $s.="${color}listed<br />";
                            while (my ($k,$v) = each(%Whitelist)) {      # and all personal
                                if ($k =~ /^\Q$ad\E,/i) {
                                    if ($v < 9999999999) {
                                        $s.="$k personal Whitelisted<br />";
                                    } else {
                                        $s.="<span class=\"negative\">$k personal not Whitelisted</span><br />";
                                    }
                                }
                            }
                        } else {
                            $s.="<span class=\"negative\">NOT $qs{list}listed</span>";
                        }
                    } else {
                        if($list->{$ad}) {
                            $s.="${color}listed";
                        } else {
                            $s.="<span class=\"negative\">NOT $qs{list}listed</span>";
                        }
                    }
                } elsif($act eq 'a') {
                    $ap = '' if $ap eq ',*';
                    if ($list eq 'Redlist') {
                        if(exists $list->{$ad}) {
                            $s.="<span class=\"positive\">already $qs{list}listed</span>";
                        } else {
                            $list->{$ad}=time;
                            mlog(0,"Admininfo: $qs{list}list addition: $ad (by $WebIP{$ActWebSess}->{user})");
                            $s.="added to $list";
                        }
                    } else {
                        if($ap && &Whitelist($ad,$ap,'')) {
                            $s.="<span class=\"positive\">already $qs{list}listed for $ap</span>";
                        } elsif (! $ap && &Whitelist($ad,'','')) {
                            $s.="<span class=\"positive\">already $qs{list}listed</span>";
                        } else {
                            $s.="$ap " if $ap;
                            $s.="added to $list";
                            Whitelist($ad,$ap,'add');
                            $s .= '<br />' . join('',@WhitelistResult);
                            mlog(0,"Admininfo: $qs{list}list addition: $ad (by $WebIP{$ActWebSess}->{user})");
                            mlog(0,"Admininfo: $qs{list}list addition: $ad$ap (by $WebIP{$ActWebSess}->{user})") if $ap;

                            $ap =~ s/^,(?:\@.+)//o;
                            if ($ap && (my $pb = PersBlackFind($ap,$ad))) {
                                PersBlackRemove($ap, $pb);
                                $s .= "<br />$pb: deleted from the personal blacklist of $ad";
                                mlog( 0, "Admininfo: $pb: deleted from the personal blacklist of $ad (by $WebIP{$ActWebSess}->{user})", 1 );
                            }
                        }
                    }
                } elsif($act eq 'r') {
                    $ap = '' if $ap eq ',*';
                    if ($list eq 'Redlist') {
                        if ($list->{$ad}) {
                            $s.="removed from $list<br />";
                            delete $list->{$ad};
                            mlog(0,"Admininfo: $qs{list}list deletion: $ad (by $WebIP{$ActWebSess}->{user})");
                        } else {
                            $s.="not $qs{list}listed";
                        }
                    } else {
                        if($ap && $ap !~ /^,\@/o && $list->{"$ad$ap"} && $list->{"$ad$ap"} < 9999999999) {
                            $s.="$ap " if $ap;
                            $s.="removed from $list";
                            &Whitelist($ad,$ap,'delete');
                            $s .= '<br />' . join('',@WhitelistResult);
                            mlog(0,"Admininfo: $qs{list}list deletion: $ad$ap (by $WebIP{$ActWebSess}->{user})");
                        } elsif ($ap && $ap =~ /^,\@/o && &Whitelist($ad,$ap,'')) {
                            $s.="$ap " if $ap;
                            $s.="removed from $list";
                            &Whitelist($ad,$ap,'delete');
                            $s .= '<br />' . join('',@WhitelistResult);
                            mlog(0,"Admininfo: $qs{list}list deletion: $ad$ap (by $WebIP{$ActWebSess}->{user})");
                        } elsif (! $ap && $list->{$ad}) {
                            $s.="removed from $list<br />";
                            &Whitelist($ad,'','delete');
                            $s .= '<br />' . join('',@WhitelistResult);
                            mlog(0,"Admininfo: $qs{list}list deletion: $ad (by $WebIP{$ActWebSess}->{user})");
                        } else {
                            $s.="not $qs{list}listed";
                        }
                    }
                }
                $s.="</div>\n";
            }
#        } else {
        }
    }
    @WhitelistResult = ();
    if($qs{B1}=~/^Show (.)/io) {
        local $/="\n";
        if($1 eq 'R') {
            $qs{list}="red"; # update radios
            $s.='<div class="textbox"><b>Redlist</b></div>';
            $s.='<div class="textbox"><b>database</b></div>';
            while (my($ad,$v)=each(%Redlist)) {
                $s.="<div class=\"textbox\">$ad</div>";
            }
        } else {
            $qs{list}="white"; # update radios
            $s.='<div class="textbox"><b>Whitelist</b></div>';
            $s.='<div class="textbox"><b>database</b></div>';
            while (my($ad,$v)=each(%Whitelist)) {
                if ($ad =~ /,/io) {
                    if ($v < 9999999999) {
                        $s.="<div class=\"textbox\">$ad</div>";
                    } else {
                        $s.="<div class=\"textbox\"><span class=\"negative\">$ad personal not Whitelisted</span></div>";
                    }
                } else {
                    $s.="<div class=\"textbox\">$ad</div>";
                }
            }
        }
    }
    my $h1 = $WebIP{$ActWebSess}->{lng}->{'msg500031'} || $lngmsg{'msg500031'};
    my $h2 = $WebIP{$ActWebSess}->{lng}->{'msg500032'} || $lngmsg{'msg500032'};
    my $h3 = $WebIP{$ActWebSess}->{lng}->{'msg500033'} || $lngmsg{'msg500033'};
    my $h4 = $WebIP{$ActWebSess}->{lng}->{'msg500034'} || $lngmsg{'msg500034'};

<<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
<h2>Update or Verify the Whitelist/Redlist</h2>
$s
<form method="post" action=\"\">
    <table class="textBox" style="width: 99%;">
        <tr>
            <td class="noBorder">$h1
            </td>
            <td class="noBorder">
            <input type="radio" name="list" value="white"${\((!$qs{list} || $qs{list} eq 'white') ? ' checked="checked" ' : ' ')} /> Whitelist or<br />
            <input type="radio" name="list" value="red"${\($qs{list} eq 'red' ? ' checked="checked" ' : ' ')} /> Redlist or<br />
            <input type="radio" name="list" value="tuplets"${\($qs{list} eq 'tuplets' ? ' checked="checked" ' : ' ')} /> Tuplets
            </td>
        </tr>
        <tr>
            <td class="noBorder">$h2 </td>
            <td class="noBorder"><input type="radio" name="action" value="a" />add<br />
            <input type="radio" name="action" value="r" />remove<br />
            <input type="radio" checked="checked" name="action" value="v" />or verify</td>
            <td class="noBorder">
                List the addresses in this box:<br />
                (for tuplets put: ip-address,domain-name)<br />
                <p><textarea name="addresses" rows="5" cols="40" wrap="off">$qs{addresses}</textarea></p>
            </td>
        </tr>
        <tr>
            <td class="noBorder">&nbsp;</td>
            <td class="noBorder"><input type="submit" name="B1" value="  Submit  " /></td>
            <td class="noBorder">&nbsp;</td>
        </tr>
    </table>
</form>
<div class="textBox">
$h3
  <form action="" method="post">
  <table style="width: 90%; margin-left: 5%;">
    <tr>
      <td align="center" class="noBorder"><input type="submit" name="B1" value="Show Whitelist" /></td>
      <td align="center" class="noBorder"><input type="submit" name="B1" value="Show Redlist" /></td>
    </tr>
  </table>
  </form>
  $h4
<form name="ASSPconfig" id="ASSPconfig" action="" method="post">
  <input name="theButtonLogout" type="hidden" value="" />
</form>
</div>
</div>
$footers
</body></html>
EOT
}
