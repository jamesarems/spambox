#line 1 "sub main::textnoinput"
package main; sub textnoinput {my ($name,$nicename,$size,$func,$default,$valid,$onchange,$description,$cssoption,$note,$lngNice,$lngDesc)=@_;
 my $Error;
# $Error = checkUpdate($name,$valid,$onchange,$nicename);
 my $value = encodeHTMLEntities($Config{$name});
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
 my $edit  = '';
 $note=1 if !$note;

 if ($value=~/^\s*file:\s*(.+)\s*/io){
  # the optionlist is actually saved in a file.
  my $fil = normHTMLfile($1);
  $edit = "<input type=\"button\" value=\" Edit file \" onclick=\"javascript:popFileEditor(\'$fil\',$note);setAnchor('$name');\" />";
 }
 if (! $rootlogin && (exists $cryptConfigVars{$name} ||
      ! &canUserDo($user,'cfg',$name)))
 {
     $name = 'AD' . $name;
     $value = 'n/a';
     return  "<a name=\"$name\"></a><input name=\"$name\" type=\"hidden\" value=\"$value\">\n"  if $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"};
     $edit = '' ;
     $cfgname = $EnableInternalNamesInDesc?"($name)":'';
     $description = '';
     $Error = "<span class=\"negative\"><b>*** access denied ***</b></span><br />";
 }
 $edit = '' if(! $rootlogin && ! &canUserDo($user,'action','edit'));
 # get rid of google autofill
 #$name=~s/(e)(mail)/$1_$2/gio;
 if ($mobile) {
     if ($description =~ s/^(.+?[\.!:])((?: |\<br).*)$/$1/ois) {
         my $text = $2;
         my @inputs = $text =~ /(\<input[^\>]+\/\>)/goi;
         if (@inputs) {
             $description .= '<br />' . join('',@inputs);
         }
     }
 }
 return "<a name=\"$name\"></a>
 <div class=\"shadow\">
  <div class=\"option\">
   <div class=\"optionTitle$cssoption\">$nicename $cfgname</div>
   <div class=\"optionValue\">
    <input name=\"$name\" readonly style=\"background:#eee none; color:#222; font-style: italic\" size=\"$size\" value=\"$value\" />
    $edit<br />
    $Error
    $description\n
   </div>
  </div>
  &nbsp;
 </div>";

}
