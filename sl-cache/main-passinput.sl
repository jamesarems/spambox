#line 1 "sub main::passinput"
package main; sub passinput {my ($name,$nicename,$size,$func,$default,$valid,$onchange,$description,$cssoption,$note,$lngNice,$lngDesc)=@_;
 my $Error=checkUpdate($name,$valid,$onchange,$nicename);
 my $value=encodeHTMLEntities($Config{$name});
 my $hdefault = encodeHTMLEntities($default);
 my $color = ($value eq $hdefault) ? '' : 'style="color:#8181F7;"';
 my $showdefault;
 my $user = $WebIP{$ActWebSess}->{user};
 if (exists $WebIP{$ActWebSess}->{lng}->{$lngNice}) {
     $nicename = $WebIP{$ActWebSess}->{lng}->{$lngNice};
 }
 if (exists $WebIP{$ActWebSess}->{lng}->{$lngDesc}) {
     $description = $WebIP{$ActWebSess}->{lng}->{$lngDesc};
 }
 $description = &niceLink($description);
 $hdefault =~ s/'|"|\n//go;
 $hdefault =~ s/\\/\\\\/go;
 $showdefault = $hdefault ? $hdefault : '&nbsp;';
 my $cfgname = $EnableInternalNamesInDesc ?"<a href=\"javascript:void(0);\"$color onmouseover=\"showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>default value:</td><td>$showdefault</td></tr></table>', this, event, '450px', '1'); return true;\" onmouseout=\"window.status='';return true;\"><i>($name)</i></a>":'';
 $cfgname = "($name)" if $EnableInternalNamesInDesc && $mobile;
 $cfgname .= syncShowGUI($name);
 my $edit;

 my $style;
 if (! $rootlogin && ($name eq 'webAdminPassword' ||
      exists $cryptConfigVars{$name} ||
      ! &canUserDo($user,'cfg',$name)))
 {
     $name = 'AD' . $name;
     $value = 'n/a';
     return  "<a name=\"$name\"></a><input name=\"$name\" type=\"hidden\" value=\"$value\">\n"  if $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"};
     $edit = 'readonly' ;
     $cfgname = $EnableInternalNamesInDesc?"($name)":'';
     $style = 'style="background:#eee none; color:#222; font-style: italic"';
     $description = '';
     $Error = "<span class=\"negative\"><b>*** access denied ***</b></span><br />";
 }
 my $type = $rootlogin ? '': 'type="password"';
 $type = 'type="password"' if $name eq 'SSLPKPassword';
 if ($mobile) {
     if ($description =~ s/^(.+?[\.!:])((?: |\<br).*)$/$1/ois) {
         my $text = $2;
         my @inputs = $text =~ /(\<input[^\>]+\/\>)/goi;
         if (@inputs) {
             $description .= '<br />' . join('',@inputs);
         }
     }
 }

"<a name=\"$name\"></a>
 <div class=\"shadow\">
 <div class=\"option\">
  <div class=\"optionTitle$cssoption\">$nicename $cfgname</div>
  <div class=\"optionValue\"><input $type $edit $style name=\"$name\" size=\"$size\" value=\"$value\" onfocus=\"setAnchor('$name');return false;\" /><br />\n$Error$description
  </div>
 </div>
 &nbsp;
 </div>";
}
