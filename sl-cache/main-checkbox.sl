#line 1 "sub main::checkbox"
package main; sub checkbox {my ($name,$nicename,$size,$func,$default,$valid,$onchange,$description,$cssoption,$note,$lngNice,$lngDesc)=@_;
 my $Error=checkUpdate($name,$valid,$onchange,$nicename);
 my $checked=$Config{$name}?'checked="checked"':'';
 if (exists $ConfigAdd{$name}) {
     $checked=$ConfigAdd{$name}?'checked="checked"':'';
 }
 my $disabled = '';
 my $isrun = '';
 my $user = $WebIP{$ActWebSess}->{user};
 if (exists $WebIP{$ActWebSess}->{lng}->{$lngNice}) {
     $nicename = $WebIP{$ActWebSess}->{lng}->{$lngNice};
 }
 if (exists $WebIP{$ActWebSess}->{lng}->{$lngDesc}) {
     $description = $WebIP{$ActWebSess}->{lng}->{$lngDesc};
 }
 $description = &niceLink($description);

 if (($name =~ /forceLDAPcrossCheck/o) && ($RunTaskNow{forceLDAPcrossCheck} || (! $CanUseLDAP && ! $CanUseNetSMTP) || ! $ldaplistdb)) {
   $disabled = "disabled";
   $isrun = 'LDAPlist (ldaplistdb) is not configured - not available!<br />' if (! $ldaplistdb);
   $isrun .= 'module Net::LDAP is not available!<br />' if (! $CanUseLDAP);
   $isrun .= 'module Net::SMTP is not available!<br />' if (! $CanUseNetSMTP);
 }
 if (exists $RunTaskNow{$name} && $RunTaskNow{$name} && $qs{$name}) {
   ${$name} = '';
   $Config{$name} = '';
   $qs{$name} = '';
   $disabled = "disabled";
   $isrun .= "task $name (or related task) is just running - not available now!<br />Refreshing your browser will possibly restart $name, instead use the 'Refresh Browser' button to refresh the browser!<br />";
 }
 my $hdefault = $default ? 'on' : 'off' ;
 my $cdefault = $default ? 'true' : 'false' ;
 my $color = ($Config{$name} eq $default) ? '' : 'style="color:#8181F7;"';
 if (exists $ConfigAdd{$name}) {
     $color = ($ConfigAdd{$name} eq $default) ? '' : 'style="color:#8181F7;"';
 }
 my $cfgname = $EnableInternalNamesInDesc?"<a href=\"javascript:void(0);\"$color onmousedown=\"document.forms['SPAMBOXconfig'].$name.checked=$cdefault;setAnchor('$name');return false;\" onmouseover=\"showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>click to reset<br />to default value</td><td>$hdefault</td></tr></table>', this, event, '450px', '1'); return true;\" onmouseout=\"window.status='';return true;\"><i>($name)</i></a>":'';
 $cfgname = "($name)" if $EnableInternalNamesInDesc && $mobile;
 $cfgname .= syncShowGUI($name);
 my $display = '';
 if (! $rootlogin && (exists $cryptConfigVars{$name} ||
      ! &canUserDo($user,'cfg',$name)))
 {
     $name = 'AD' . $name;
     return  "<a name=\"$name\"></a><input name=\"$name\" type=\"hidden\" value=\"1\">\n"  if $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"};
     $display = 'readonly';
     $disabled = "disabled";
     $cfgname = $EnableInternalNamesInDesc?"($name)":'';
     $description = '';
     $isrun = '';
     $checked = '';
     $Error = "<span class=\"negative\"><b>*** access denied ***</b></span><br />";
 }
 if ($mobile) {
     if ($description =~ s/^(.+?[\.!:])((?: |\<br).*)$/$1/ois) {
         my $text = $2;
         my @inputs = $text =~ /(\<input[^\>]+\/\>)/goi;
         if (@inputs) {
             $description .= '<br />' . join('',@inputs);
         }
     }
 }

  my $edit;
  my @reportIncludes;
  my $act = 'edit';
  if (exists $ReportFiles{$name} && &canUserDo($user,'cfg',$name)) {
      my $what = "report file: $ReportFiles{$name}";
      my $note = 2;
      %seenReportIncludes = ();
      @reportIncludes = ReportIncludes($ReportFiles{$name});
      my $fil = normHTMLfile($ReportFiles{$name});
      $edit .= "<input type=\"button\" value=\" $act $what \" onclick=\"javascript:popFileEditor(\'$fil\',$note);setAnchor('$name');\" /><br />";
  }
  foreach my $f (@reportIncludes) {
      my $fi = $f;
      my $note = 2;
      $f  = normHTMLfile($f);
      $edit .= "<input type=\"button\" value=\" $act included file $fi \" onclick=\"javascript:popFileEditor(\'$f\',$note);setAnchor('$name');\" /><br />";
  }

 "<a name=\"$name\"></a>
 <div class=\"shadow\">
 <div class=\"option\">
  <div class=\"optionTitle$cssoption\">
   <input type=\"checkbox\" $disabled $display name=\"$name\" value=\"1\" $checked onfocus=\"setAnchor('$name');return false;\"/><span style=\"color:red\">$isrun</span>$nicename $cfgname<br /></div>
  <div class=\"optionValue\">$edit\n$Error$description
  </div>
 </div>
 &nbsp;
 </div>";
}
