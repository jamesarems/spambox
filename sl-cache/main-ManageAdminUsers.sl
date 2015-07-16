#line 1 "sub main::ManageAdminUsers"
package main; sub ManageAdminUsers {
    my $s;
    my $sfoot;
    my $display;
    my $options;
    %qs = () unless($qs{theButton} or $qs{theButtonX} or $qs{theButtonA} or $qs{theButtonDelete} or $qs{showLDAP});
    my $suser = $qs{suser};
    my $user = $qs{user};
    $user = '' if $qs{showLDAP};
    my $toTop;
#    mlog(0,"info: suser=$suser user=$user");
    my $buttons = <<EOT;
<div class="rightButton">
  <input name="theButton" type="submit" value="Continue" onclick="WaitDiv();"/>
  <input name="theButtonCancel" type="button" value="Cancel" onclick="window.location.href='./';return false;"/>
  <input name="theButtonLogout" type="button" value="Logout" onclick="eraseCookie('lastAnchor');window.location.href='./logout';return false;"/>
</div>
EOT
    my $applybutton = <<EOT;
  <input name="theButtonA" type="submit" align="left" value="Apply Changes" onclick="WaitDiv();"/>
  <input name="theButton" align="right" type="submit" value="Continue" onclick="WaitDiv();"/>
  <input name="theButtonCancel" align="right" type="button" value="Cancel" onclick="window.location.href='./';return false;"/>
  <input name="theButtonLogout" align="right" type="button" value="Logout" onclick="eraseCookie('lastAnchor');window.location.href='./logout';return false;"/>
EOT
    my $mainhint = $WebIP{$ActWebSess}->{lng}->{'msg500020'} || $lngmsg{'msg500020'};

    $s = <<EOT;
$headerHTTP
$headerDTDTransitional
$headers
<script type="text/javascript">
<!--
function showDisp(nodeid) {}
function expand(expand, force) {}
function setAnchor(iname) {}
// -->
</script>
<div id="cfgdiv" class="content">
<h2>Manage Admin Users!</h2>
<div>
$mainhint
</div>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
<input name="theButtonX" type="hidden" value="" onclick="WaitDiv();"/>
EOT
    $sfoot = <<EOT;
</form>
</div>
$footers
</body></html>
EOT


    if (! ($adminusersdb && $adminusersdbpass) ) {

       my $missing = ($adminusersdb ? '' : <<EOT) ;
<h2><span class="negative">Please configure <a href="./#adminusersdb" style="color:#684f00" onmousedown="showDisp(\'$ConfigPos{adminusersdb}\');gotoAnchor(\'adminusersdb\');return false;" >adminusersdb</a> first!</span></h2>
EOT
       $missing .= ($adminusersdbpass ? '' : <<EOT) ;
<h2><span class="negative">Please configure <a href="./#adminusersdbpass" style="color:#684f00" onmousedown="showDisp(\'$ConfigPos{adminusersdbpass}\');gotoAnchor(\'adminusersdbpass\');return false;" >adminusersdbpass</a> first!</span></h2>
EOT
       return <<EOT ;
$headerHTTP
$headerDTDTransitional
$headers
<div id="cfgdiv" class="content">
$missing
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
<input name="theButtonLogout" align="right" type="button" value="Logout" onclick="eraseCookie('lastAnchor');window.location.href='./logout';return false;"/>
</form>
</div>
$footers
</body></html>
EOT
    }

    $AdminUsers{'~DEFAULT'} = '' if (! exists $AdminUsers{'~DEFAULT'}) ;
# select user
    if ($qs{theButtonDelete} && $suser) {
        if ($suser !~ /^\~DEFAULT|\#/o) {
            while (my ($k,$v) = each(%AdminUsersRight)) {
                delete $AdminUsersRight{$k}
                    if ($k =~ /^$suser\./ or $v eq "refto($suser)");
            }
            delete $AdminUsers{$suser};
            mlog(0,"info: AdminUser $suser deleted by root");
            my $t = $suser =~ /^\~/o ? 'template' : 'user';
            $s .= "<hr><span class=\"positive\">$t $suser was successful deleted</span><br/ >";
        } else {
            my $t = $suser =~ /^\~/o ? 'template' : 'user';
            $s .= "<hr><span class=\"negative\">you cannot delete $t $suser</span><br/ >";
        }
        $suser = '';
        $user = '';
        %qs = ();
        $toTop = 1;
        %ManageAdminUser = ();
        %ManageActions = ();
        %ManagePerm = ();
        $AdminUsersObject->flush();
        $AdminUsersRightObject->flush();
    }
    
    if (($user && $suser ne $user && $suser !~ /^\#/o) or ($ManageAdminUser{suser} && $ManageAdminUser{suser} ne $suser)) {
        $user = '';
        %qs = ();
        $toTop = 1;
        %ManageAdminUser = ();
        $ManageAdminUser{suser} = $suser if $suser;
        %ManageActions = ();
        %ManagePerm = ();
    }
        
    my %userselect = ( '#newUser' => 1, '#newTemplate' => 1);
    foreach (sort keys %AdminUsers) {$userselect{$_} = 1;}
    
    foreach my $k (sort keys %userselect) {
        if ( $user eq $k or $suser eq $k) {
            $options .= "<option selected=\"selected\" value=\"$k\">$k</option>";
        } else {
            $options .= "<option value=\"$k\">$k</option>";
        }
    }
    $s .= "<hr>
    <div class=\"shadow\">
    <div class=\"option\">
    <div class=\"optionValue\"><b>select user : </b>
    <span style=\"z-Index:100;\"><select size=\"1\" name=\"suser\">
    $options
    </select></span>&nbsp;&nbsp;&nbsp;&nbsp;
    <input name=\"theButtonDelete\" type=\"submit\" value=\"delete user\" onclick=\"WaitDiv();\"/>
    </div></div></div><hr>
    ";

    if (! $suser || $toTop) {
        $s .= $buttons.$sfoot;
        %ManageAdminUser = ();
        %ManageActions = ();
        %ManagePerm = ();
        return $s;
    }
    $ManageAdminUser{suser} = $suser;
    
# input username
    $user = $suser if (!$user && $suser !~ /^\#/o);
    if ($user) {
        $user = '' if ($user =~ /^\#/o);
        $user = '~'.$user if($user !~ /\~/o && $suser eq '#newTemplate');
    }
    $display = '';
    $display = 'readonly' if ($user);
    my $objectclass = $qs{objectclass} || 'person'; $objectclass=~s/\s//go;
    my $attr = $qs{attr} || 'uid'; $attr=~s/\s//go;
    my $sBase = $qs{base} || ''; $sBase=~s/\s//go;
    my $sHost = $qs{host} || ''; $sHost=~s/\s//go;
    my $sSetting = $qs{setting} || '';
    $s .= "<div class=\"shadow\"><div class=\"option\"><div class=\"optionValue\">
<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\"99%\" >
<tr><td><b>user name : </b></td><td><input name=\"user\" size = \"30\" $display value=\"$user\" />&nbsp;&nbsp;type in the user name or select it from the LDAP search below</td></tr>";
    if ($LDAPHost && $CanUseLDAP && ! $user && $suser ne '#newTemplate') {
        $s .= "
            <tr><td><b>show LDAP users : </b><br />
               if nothing is defined, the default LDAP setup<br />
               will be used to get a list of possible users</td><td>
            select : <input name=\"selLDAP\" size = \"40\" value=\"$qs{selLDAP}\" />&nbsp;&nbsp;
            <input name=\"showLDAP\" type=\"submit\" value=\"show\" onclick=\"WaitDiv();\"/>
            <br />wildcards * and ? are supported<br />example: adm* or ?.meyer*<br /><br />
            <table BORDER CELLSPACING=0 CELLPADDING=4>
                <tr><td>LDAP host : </td><td><input name=\"host\" size = \"40\" value=\"$sHost\" /></td></tr>
                <tr><td>LDAP search base : </td><td><input name=\"base\" size = \"40\" value=\"$sBase\" /></td></tr>
                <tr><td>LDAP objectclass : </td><td><input name=\"objectclass\" size = \"40\" value=\"$objectclass\" /></td></tr>
                <tr><td>LDAP return attribute : </td><td><input name=\"attr\" size = \"40\" value=\"$attr\" /></td></tr>
            </table>
            </td></tr>
            <tr><td><b>LDAP custom settings : </b></td><td>
                <table BORDER CELLSPACING=0 CELLPADDING=4>
                   <tr><td>
                     <input name=\"setting\" size = \"100\" value=\"$sSetting\" /><br />
                     (version => 3/2, schema => ldap[s], starttls => 1/0, timeout => 3, user => [name], password => [pass])
                   </td></tr>
                </table>
            </td></tr>";
    }
    $s .= "</table></div></div></div><hr>";
    if (! $user || $user eq 'root' || (exists $AdminUsers{$user} && $suser =~ /^\#/o)) {
        $s .= "wrong user name - $user already exists" if exists $AdminUsers{$user};
        $s .= "wrong user name - root is not manageable" if $user eq 'root';

        unless ($user) {
            $s .= "username required<br />";
            my %ldap = ('host' => $sHost, 'base' => $sBase, 'ldapfilt' => '(objectclass='. $objectclass .')', 'attr' => $attr, split(/\s*(?:,|=>)\s*/o,$sSetting));
            if ($LDAPHost &&
                $CanUseLDAP &&
                $qs{showLDAP} &&
                $suser ne '#newTemplate' &&
                (my @ldapusers = sort {"\U$main::a" cmp "\U$main::b"} &LDAPList(%ldap))) {

    $s .= "<div class=\"shadow\"><div class=\"option\"><div class=\"optionValue\">
<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\"99%\" HIGH=\"30%\">
<tr><td WIDTH=\"20%\">
<b>users available via LDAP:</b><br />click the name to select</td><td>";

                my $regex = $qs{selLDAP};
                $regex =~ s/\./\\\./o;
                $regex =~ s/\*/\.\*/o;
                $regex =~ s/\?/\./o;
                $regex = '.*' unless $regex;
                use re 'eval';
                if ($regex !~ /\*|\?/o) {
                    eval{$regex=qr/(?i)$regex/};
                } else {
                    eval{$regex=qr/^(?i)$regex$/};
                }
                my $fchar; $fchar = lc substr($ldapusers[0],0,1) if @ldapusers;
                while (@ldapusers) {
                    my $un = shift @ldapusers;
                    next unless $un;
                    if ($un =~ /$regex/) {
                        if (lc substr($un,0,1) ne $fchar) {
                            $fchar = lc substr($un,0,1);
                            $s =~ s/,$//o;
                            $s .= '<br /><br />';
                        }
                        $s .= "<a href=\"javascript:void(0);\" onmousedown=\"document.forms['SPAMBOXconfig'].user.value='$un';return false;\"> $un </a>,";
                    }
                }
                $s =~ s/,$//o;
                $s .= "</td></tr></table></div></div></div><hr>";
            }
        }
        $s .= $buttons.$sfoot;
        %ManageActions = ();
        %ManagePerm = ();
        return $s;
    }

# define password handling
    my $actPassCfg = $qs{actPassCfg};

    my $password = $qs{password};
    $password = Digest::MD5::md5_hex($password) if ($password && $password !~ /^[a-fA-F0-9]{32}$/o);
    my $passwordExp = $qs{passwordExp};
    my $passwordExpInt = $qs{passwordExpInt};
    my $disabled = $qs{disabled};
    my $languageFile = $qs{languageFile};
    my $hidDisabled = $qs{hidDisabled};
    my $LDAPserver = $qs{LDAPserver};
    my $LDAPversion = $qs{LDAPversion};
    my $LDAProot = $qs{LDAProot};
    my $LDAPssl = $qs{LDAPssl};

    if (!$actPassCfg) {
        $password ||= $AdminUsers{$user};
        $passwordExp ||= $AdminUsersRight{"$user.user.passwordExp"};
        $passwordExpInt ||= $AdminUsersRight{"$user.user.passwordExpInt"} || 30;
        $disabled ||= $AdminUsersRight{"$user.user.disabled"};
        $languageFile ||= $AdminUsersRight{"$user.user.languageFile"};
        $hidDisabled ||= $AdminUsersRight{"$user.user.hidDisabled"};
        $LDAPserver ||= $AdminUsersRight{"$user.user.LDAPserver"};
        if ($password) {
            $LDAPserver ||= $qs{LDAPserver};
        } else {
            $LDAPserver ||= $LDAPHost;
        }
        $LDAPversion ||= $AdminUsersRight{"$user.user.LDAPversion"} || $LDAPVersion || 3;
        $LDAProot ||= $AdminUsersRight{"$user.user.LDAProot"};
        $LDAPssl ||= $AdminUsersRight{"$user.user.LDAPssl"};
        if ($password) {
            $LDAPssl ||= $qs{LDAPssl};
        } else {
            $LDAPssl ||= $DoLDAPSSL;
        }
    }

    $s .= "<div class=\"shadow\"><div class=\"option\"><div class=\"optionValue\">";
    $s .= "<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\"50%\" >";
    $display = '';
    $display = 'readonly' if ($suser =~ /^\#newTemplate/o or $suser =~ /^\~/o);
    $s .= "<tr><td><b>local password : </b></td><td><input name=\"password\" type=\"password\" size = \"20\" $display value=\"$password\" /></td></tr>";
    $display = '';
    my $checked=$passwordExp?'checked="checked"':'';
    $s .= "<tr><td><b>set local password to expired: </b></td><td><input name=\"passwordExp\" type=\"checkbox\" $checked value=\"1\" /></td></tr>";
    $s .= "<tr><td><b>local password expiration interval : </b></td><td><input name=\"passwordExpInt\" size = \"5\" value=\"$passwordExpInt\" /></td></tr>";
    $checked=$disabled?'checked="checked"':'';
    $s .= "<tr><td><b>disable the user : </b></td><td><input name=\"disabled\" type=\"checkbox\" $checked value=\"1\" /></td></tr>";

    my $lFoptions = "<option value=\"default\">default</option>";
    my @DIR = Glob("$base/language/*");
    while (@DIR) {
        $_ = shift @DIR;
        my $sel = '';
        next if /[\/\\]spambox\.lng$/o;
        next if /[\/\\]default_en_msg_[^\/\\]+$/o;
        s/\Q$base\E\/language\///o;
        $sel = "selected=\"selected\"" if $_ eq $languageFile;
        $lFoptions .= "<option $sel value=\"$_\">$_</option>";
    }
    $s .= "
    <tr><td><b>language file : </b></td><td>
    <span style=\"z-Index:100;\"><select size=\"1\" name=\"languageFile\">
    $lFoptions
    </select></span><br />select a language file or default</td></tr>
    ";

    $checked=$hidDisabled?'checked="checked"':'';
    $s .= "<tr><td><b>hid disabled config: </b></td><td><input name=\"hidDisabled\" type=\"checkbox\" $checked value=\"1\" /></td></tr>";
    $s .= "<tr><td><b>use LDAP / LDAP host : </b></td><td><input name=\"LDAPserver\" size = \"20\" value=\"$LDAPserver\" /><br />host/ip[:port]<br />If port is not defined, the default port (389/636) will be used.</td></tr>";
    $s .= "<tr><td><b>LDAP version : </b></td><td>";
    $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"LDAPversion\">";
    my $sel = '';
    $sel = "selected=\"selected\"" if ($LDAPversion == 1);
    $s .= "<option $sel value=\"1\">1</option>";
    $sel = '';
    $sel = "selected=\"selected\"" if ($LDAPversion == 2);
    $s .= "<option $sel value=\"2\">2</option>";
    $sel = '' ;
    $sel = "selected=\"selected\"" if ($LDAPversion == 3);
    $s .= "<option $sel value=\"3\">3</option>";
    $s .= "</select></span></td></tr>";
    $s .= "<tr><td><b>LDAP container : </b></td><td><input name=\"LDAProot\" size = \"20\" value=\"$LDAProot\" /><br />\"cn=USER, o=org, c=country\"<br />the literal 'USER' will be relaced with the username</td></tr>";


    $s .= "<tr><td><b>use SSL for LDAP: </b></td><td>";
    $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"LDAPssl\">";
    $sel = '';
    $sel = "selected=\"selected\"" if (!$LDAPssl);
    $s .= "<option $sel value=\"0\">no</option>";
    $sel = '';
    $sel = "selected=\"selected\"" if ($LDAPssl == 1);
    $s .= "<option $sel value=\"1\">SSL</option>";
    $sel = '' ;
    $sel = "selected=\"selected\"" if ($LDAPssl == 2);
    $s .= "<option $sel value=\"2\">TLS</option>";
    $s .= "</select></span>&nbsp; select SSL in doubt!</td></tr>";

    if ($user ne $suser) {
        $s .= "<tr><td>&nbsp;</td><td>&nbsp;</td></tr>";
        $s .= "<tr><td><b>enable this user/password configuration : </b></td><td>";
        $sel = '' ;
        $sel = "selected=\"selected\"" if ($actPassCfg eq 'enable');
        $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"actPassCfg\">
              <option value=\"\">select</option>
              <option $sel value=\"enable\">enable</option>
              </select></span></td></tr></table></div></div></div><hr>";
    } else {
        $s .= "</table></div></div></div><hr><input name=\"actPassCfg\" type=\"hidden\" value=\"enable\" />";
        $actPassCfg = 'enable';
    }
    if ($actPassCfg ne 'enable') {
        $s .= $buttons.$sfoot;
        %ManageActions = ();
        %ManagePerm = ();
        return $s;
    }
    if (!$password && !$LDAPserver && !$disabled && $user !~ /^\~/o && $suser ne '#newTemplate') {
        $s .= "Please define password or LDAPserver, or disable the user!<br />";
        $s .= $buttons.$sfoot;
        %ManageActions = ();
        %ManagePerm = ();
        return $s;
    }

# select action to take on user
    my $crFrom = $qs{crFrom};
    $options = "<option selected=\"selected\" value=\"none\">none</option>";
    $options .= "<option value=\"enable_all\">enable all</option>";
    $options .= "<option value=\"disable_all\">disable all</option>";
    foreach my $k (sort keys %AdminUsers) {
        $options .= "<option value=\"c!$k\">copy from $k</option>" if $k ne $user;
        if ($k =~ /^\~/o && $user !~ /^\~/o) {
            $options .= "<option value=\"r!$k\">reference to $k</option>";
        }
    }
    my $ss = "<td><b>set all permissions to : </b></td><td>";
    $ss .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"crFrom\">
          $options
          </select></span></td>";

# select permission
    my $selmain = $qs{selmain};
    my $selregex = $qs{selregex};
    my %selKey = ('all' => 1, 'enabled' => 1, 'disabled' =>1 , 'referenced' => 1);
    $options = '';
    foreach my $k (sort keys %selKey) {
        if ( $selmain eq $k ) {
            $options .= "<option selected=\"selected\" value=\"$k\">$k</option>";
        } else {
            $options .= "<option value=\"$k\">$k</option>";
        }
    }
    $s .= "<div class=\"shadow\"><div class=\"option\"><div class=\"optionValue\">";
    $s .= "<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\"99%\" >";
    $s .= "<tr><td><b>select parms : </b></td><td>";
    $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"selmain\">";
    $s .= $options;
    $s .= "</select></td>";
    $s .= "<td><b>parms contain string : </b></td><td>";
    $s .= "<input name=\"selregex\" size = \"20\" value=\"$selregex\" /><br />wildcards * and ? are supported<br />example: *local* or ldap*</td>";
    $s .= $ss;
    $s .= "</tr></table>";
    $s .= "</div></div></div><hr>";

    if ($user eq $suser && ! $selmain) {
        $selmain = 'all';
        $crFrom = 'none';
    }

    if (! $selmain) {
        $s .= $buttons.$sfoot;
        %ManageActions = ();
        %ManagePerm = ();
        return $s;
    }
    my $regex = $selregex;
    $regex =~ s/\./\\\./o;
    $regex =~ s/\*/\.\*/o;
    $regex =~ s/\?/\./o;
    $regex = '.*' unless $regex;
    use re 'eval';
    if ($regex !~ /\*|\?/o) {
        eval{$regex=qr/(?i)$regex/};
    } else {
        eval{$regex=qr/^(?i)$regex$/};
    }

# manage permissions
###########################

# manage Action permissions

    my %ManageActionsDesc = ();
    $ManageActionsDesc{lists} = 'White/Redlist/Tuplets';
    $ManageActionsDesc{recprepl} = 'Recipient Replacement Test';
    $ManageActionsDesc{maillog} = 'View Maillog Tail';
    $ManageActionsDesc{analyze} = 'Mail Analyzer';
    $ManageActionsDesc{infostats} = 'Info and Stats';
    $ManageActionsDesc{top10stats} = 'Top 10 Stats';
    $ManageActionsDesc{resetcurrentstats} = 'Reset Stats since last Start';
    $ManageActionsDesc{resetallstats} = 'Reset ALL Stats';
    $ManageActionsDesc{statusspambox} = 'Worker/DB/Regex Status';
    $ManageActionsDesc{edit} = 'Edit any Files, Lists, Caches';
    $ManageActionsDesc{shutdown_list} = 'SMTP Connections';
    $ManageActionsDesc{shutdown} = 'Shutdown/Restart';
    $ManageActionsDesc{suspendresume} = 'Suspend/Resume';
    $ManageActionsDesc{shutdown_frame} = 'Shutdown/Restart Screen';
    $ManageActionsDesc{github} = 'GitHUB';
    $ManageActionsDesc{pwd} = 'Change own local Password';
    $ManageActionsDesc{reload} = 'Load Config';
    $ManageActionsDesc{quit} = 'Terminate Now!';
    $ManageActionsDesc{save} = 'Save Config';
    $ManageActionsDesc{editinternals} = 'Edit Internal Caches';
    $ManageActionsDesc{syncedit} = 'Edit Config-Synchronzation Options';
    $ManageActionsDesc{SNMPAPI} = 'allowed to use the SNMP API';
    $ManageActionsDesc{addraction} = 'take action on email addresses from MaillogTail';
    $ManageActionsDesc{ipaction} = 'take actions on IP addresses from MaillogTail';
    $ManageActionsDesc{statgraph} = 'show graphical statistics';
    $ManageActionsDesc{confgraph} = 'show confidence distribution';
    $ManageActionsDesc{fc} = 'spambox file commander';
    $ManageActionsDesc{remotesupport} = 'Remote Support';

    my %webRequests = %webRequests;
    delete $webRequests{'/get'};
    delete $webRequests{'/adminusers'};
    delete $webRequests{'/remember'};
    foreach (keys %ManageActionsDesc) {
        delete $webRequests{'/'.$_};
    }
    foreach (keys %webRequests) {
        s/^\///;
        $ManageActionsDesc{$_} = "Plugin Action $_";
    }
    
    $s .= $applybutton.'<hr>';
    $s .= "<h2>Action Permissions</h2>";
    $s .= "<div class=\"shadow\"><div class=\"option\"><div class=\"optionValue\">";
    $s .= "<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\"80%\" >";

    foreach my $k (sort keys %ManageActionsDesc) {
        if ($crFrom eq 'none') {
            if (! exists $ManageActions{$k}) {
                $ManageActions{$k} = $AdminUsersRight{"$user.action.$k"};
            } else {
                $ManageActions{$k} = $qs{$k};
            }
        } elsif ($crFrom eq 'enable_all') {
            $ManageActions{$k} = '';
        } elsif ($crFrom eq 'disable_all') {
            $ManageActions{$k} = int(rand(1000));
        } elsif ($crFrom =~ /c\!(.+)/o) {
            $ManageActions{$k} = $AdminUsersRight{"$1.action.$k"};
        } elsif ($crFrom =~ /r\!(.+)/o) {
            $ManageActions{$k} = "refto($1)";
        }
        if ($k =~ /$regex/ &&
            (($selmain eq 'enabled' && !$ManageActions{$k}) or
             ($selmain eq 'disabled' && $ManageActions{$k}) or
             ($selmain eq 'referenced' && $ManageActions{$k} =~ /^refto\(/o) or
             ($selmain eq 'all')
            )
           ) {
            $s .= "<tr><td><b>$ManageActionsDesc{$k} : </b></td><td>";
            $options = '';
            if (!$ManageActions{$k}) {
                $options .= "<option selected=\"selected\" value=\"\">enabled</option>";
            } else {
                $options .= "<option value=\"\">enabled</option>";
            }
            if ($ManageActions{$k} && $ManageActions{$k} !~ /^refto\(/) {
                $options .= "<option selected=\"selected\" value=\"disabled\">disabled</option>";
            } else {
                $options .= "<option value=\"disabled\">disabled</option>";
            }
            foreach my $u (sort keys %AdminUsers) {
                next if ( $user eq $u ) ;
                next if ($user =~ /^\~/o);
                next if ($u !~ /^\~/o);
                my $sel = '';
                if ($ManageActions{$k} =~ /^refto\($u\)$/) {
                    $sel = "selected=\"selected\"" ;
                }
                $options .= "<option $sel value=\"refto($u)\">reference to $u</option>";
            }
            $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"$k\">";
            $s .= $options;
            $s .= "</select></td></tr>";
        } else {
            $s .= "<input name=\"$k\" type = \"hidden\" value=\"$ManageActions{$k}\" />";
        }
    }
    $s .= "</table>";
    $s .= "</div></div></div><hr>";
    $s .= $applybutton;

# manage Config permissions
    $s .= "<hr><h2>Config Parm Permissions</h2>";
    $s .= "<div class=\"shadow\"><div class=\"option\"><div class=\"optionValue\">";
    $s .= "<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\"99%\" >";
    my %ConfigVars = ();
    for my $idx (0...$#ConfigArray) {
      my $c = $ConfigArray[$idx];
      next if @{$c}==5; # skip headings
      next unless $c->[0];
      if (exists $cryptConfigVars{$c->[0]}) {
          delete $ManagePerm{$c->[0]};
          delete $AdminUsersRight{"$user.cfg.$c->[0]"};
      } else {
          $ConfigVars{$c->[0]} = $WebIP{$ActWebSess}->{lng}->{$c->[10]} ? $WebIP{$ActWebSess}->{lng}->{$c->[10]} : $c->[1];
      }
    }
    foreach my $k (sort {"\U$main::a" cmp "\U$main::b"} keys %ConfigVars) {
        if ($crFrom eq 'none') {
            if (! exists $ManagePerm{$k}) {
                $ManagePerm{$k} = $AdminUsersRight{"$user.cfg.$k"};
            } else {
                $ManagePerm{$k} = $qs{$k};
            }
        } elsif ($crFrom eq 'enable_all') {
            $ManagePerm{$k} = '';
        } elsif ($crFrom eq 'disable_all') {
            $ManagePerm{$k} = int(rand(1000));
        } elsif ($crFrom =~ /c\!(.+)/o) {
            $ManagePerm{$k} = $AdminUsersRight{"$1.cfg.$k"};
        } elsif ($crFrom =~ /r\!(.+)/o) {
            $ManagePerm{$k} = "refto($1)";
        }
        if ($k =~ /$regex/ &&
            (($selmain eq 'enabled' && !$ManagePerm{$k}) or
             ($selmain eq 'disabled' && $ManagePerm{$k}) or
             ($selmain eq 'referenced' && $ManagePerm{$k} =~ /^refto\(/o) or
             ($selmain eq 'all')
            )
           ) {
            $s .= "<tr><td><a name=\"$k\"><b>$k : </b></a></td><td>";
            $options = '';
            if (!$ManagePerm{$k}) {
                $options .= "<option selected=\"selected\" value=\"\">enabled</option>";
            } else {
                $options .= "<option value=\"\">enabled</option>";
            }
            if ($ManagePerm{$k} && $ManagePerm{$k} !~ /^refto\(/o) {
                $options .= "<option selected=\"selected\" value=\"disabled\">disabled</option>";
            } else {
                $options .= "<option value=\"disabled\">disabled</option>";
            }
            foreach my $u (sort keys %AdminUsers) {
                next if ( $user eq $u ) ;
                next if ($user =~ /^\~/o);
                next if ($u !~ /^\~/o);
                my $sel = '';
                $sel = "selected=\"selected\"" if ($ManagePerm{$k} =~ /^refto\($u\)$/);
                $options .= "<option $sel value=\"refto($u)\">reference to $u</option>";
            }
            $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"$k\">";
            $s .= $options;
            $s .= "</select></td><td>$ConfigVars{$k}</td></tr>";
        } else {
            $s .= "<input name=\"$k\" type = \"hidden\" value=\"$ManagePerm{$k}\" />";
        }
    }
    $s .= "</table>";
    $s .= "</div></div></div><hr>";

    if ($qs{theButtonX} eq 'Apply Changes' or $qs{theButtonA} eq 'Apply Changes') {  # apply
        foreach (keys %ManageActions) {
            my $key = "$user.action.$_";
            if (! $ManageActions{$_}) {
                delete $AdminUsersRight{$key};
            } else {
                $AdminUsersRight{$key} = $ManageActions{$_};
            }
        }
        foreach (keys %ManagePerm) {
            my $key = "$user.cfg.$_";
            if (! $ManagePerm{$_}) {
                delete $AdminUsersRight{$key};
            } else {
                $AdminUsersRight{$key} = $ManagePerm{$_};
            }
        }
        $AdminUsers{$user} = $password;
        $AdminUsersRight{"$user.user.passwordExp"} = $passwordExp;
        $AdminUsersRight{"$user.user.passwordExpInt"} = $passwordExpInt;
        $AdminUsersRight{"$user.user.passwordLastChange"} = time if ($suser eq '#newUser');
        $AdminUsersRight{"$user.user.disabled"} = $disabled;
        $AdminUsersRight{"$user.user.languageFile"} = $languageFile;
        $AdminUsersRight{"$user.user.hidDisabled"} = $hidDisabled;
        $AdminUsersRight{"$user.user.LDAPserver"} = $LDAPserver;
        $AdminUsersRight{"$user.user.LDAPversion"} = $LDAPversion;
        $AdminUsersRight{"$user.user.LDAProot"} = $LDAProot;
        $AdminUsersRight{"$user.user.LDAPssl"} = $LDAPssl;
        $AdminUsersObject->flush();
        $AdminUsersRightObject->flush();

        foreach (keys %WebIP) {       # delete the permission hash for any session
            %{$WebIP{$_}->{perm}} = ();
        }

        my $text = 'successful applied changes to ';
        $text .= $suser eq '#newTemplate' ? 'template ' : 'user ';
        $text .= $user;

         $s = "HTTP/1.1 200 OK
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head><meta http-equiv=\"Refresh\" content=\"1; URL=./adminusers\">
</head><body>

<script type=\"text/javascript\">
<!--
alert('$text');
// -->
</script>
</body></html>\n";
        return $s;
    }
    $s .= $applybutton.$sfoot;
    return $s;
}
