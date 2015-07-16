#line 1 "sub main::textinput"
package main; sub textinput {my ($name,$nicename,$size,$func,$default,$valid,$onchange,$description,$cssoption,$note,$lngNice,$lngDesc)=@_;
 my $Error = checkUpdate($name,$valid,$onchange,$nicename);
 my $value = encodeHTMLEntities($Config{$name});
 if (exists $ConfigAdd{$name}) {
     $value = encodeHTMLEntities($ConfigAdd{$name});
 }
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
 my $cfgname = $EnableInternalNamesInDesc?"<a href=\"javascript:void(0);\"$color onmousedown=\"document.forms['SPAMBOXconfig'].$name.value='$hdefault';setAnchor('$name');return false;\" onmouseover=\"showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>click to reset<br />to default value</td><td>$showdefault</td></tr></table>', this, event, '450px', '1'); return true;\" onmouseout=\"window.status='';return true;\"><i>($name)</i></a>":'';
 $cfgname = "($name)" if $EnableInternalNamesInDesc && $mobile;
 $cfgname .= syncShowGUI($name);
 my $edit  =  '';
 my $display = '';
 $note=1 if !$note;
 if ($name !~ /^adminuser/io &&
     $name ne 'pbdb' &&
     ($value=~/^\s*file:\s*(.+)\s*/io or
      $value=~/^\s*(DB):\s*/io or
      $name eq 'griplist' or
      exists $ReportFiles{$name})
    )
 {
      # the optionlist is actually saved in a file or is a DB.
      my $fil;
      $fil = $1 if ($value=~/^\s*file:\s*(.+)\s*/io or $value=~/^\s*(DB):\s*/io);
      my $what = 'file';
      if ($fil eq 'DB') {
          $what = 'list';
          $fil .= "-$name";
      }
      if ($name eq 'griplist') {
          $fil = $griplist;
          $note = 8;
      }
      my $act = $note == 8 ? 'Show' : 'Edit' ;
      my $ifil = $fil;
      if ($fil) {
          $fil  = normHTMLfile($fil);
          $edit = "<input type=\"button\" value=\" $act $what \" onclick=\"javascript:popFileEditor(\'$fil\',$note);setAnchor('$name');\" /><br />";
      }
      my @reportIncludes;
      if (exists $ReportFiles{$name}) {
          my $what = "report file: $ReportFiles{$name}";
          my $note = 2;
          %seenReportIncludes = ();
          @reportIncludes = ReportIncludes($ReportFiles{$name});
          my $fil = normHTMLfile($ReportFiles{$name});
          $edit .= "<input type=\"button\" value=\" $act $what \" onclick=\"javascript:popFileEditor(\'$fil\',$note);setAnchor('$name');\" /><br />";
      }
      foreach my $f (keys %{$FileIncUpdate{"$base/$ifil$name"}},@reportIncludes) {
          my $fi = $f;
          my $note = 2;
          $f  = normHTMLfile($f);
          $edit .= "<input type=\"button\" value=\" $act included file $fi \" onclick=\"javascript:popFileEditor(\'$f\',$note);setAnchor('$name');\" /><br />";
      }
 }

 if (&canUserDo($user,'cfg',$name) && &canUserDo($user,'cfg','Groups') ) {
     if ($name ne 'Groups' && $Groups =~ /^\s*file\s*:\s*(.+)\s*$/o) {
         my $file = $1;
         while (my ($k,$v) = each %GroupWatch) {
             next unless exists $GroupWatch{$k}->{$name};
             $edit .= "<input type=\"button\" value=\" edit Groups file \"  onclick=\"javascript:setAnchor('$name');popFileEditor('$file',1);\" onmouseover=\"showhint('edit Groups file $file', this, event, '250px', '1'); return true;\"><br />";
             last;
         }
     }
     if (scalar keys %GroupRE) {
         my @grp;
         foreach my $k (sort {lc($main::a) cmp lc($main::b)} keys %GroupRE ) {
             my $link = "<input type=\"button\" value=\" show group $k \"  onclick=\"javascript:setAnchor('$name');popFileEditor('files/groups_export/$k.txt',8);\" onmouseover=\"showhint('show group details for $k in exported file files/groups_export/$k.txt', this, event, '250px', '1'); return true;\">";
             if ($name eq 'Groups') {
                 push @grp, $link;
             } else {
                 push @grp, $link if exists $GroupWatch{$k}->{$name};
             }
         }
         if (@grp) {
             my $col = 5;
             $edit .= '<br />';
             $edit .=
'<a href="javascript:void(0);" onclick="setAnchor(\'$name\');document.getElementById(\'GroupsTable'.$name.'\').style.display = \'block\';return false;">show groups</a>&nbsp;&nbsp;';
             $edit .=
'<a href="javascript:void(0);" onclick="setAnchor(\'$name\');document.getElementById(\'GroupsTable'.$name.'\').style.display = \'none\';return false;">hide groups</a>';
             $edit .= '<br />';
             $edit .= "<table id='GroupsTable$name' BORDER CELLSPACING=0 CELLPADDING=4 WIDTH='95%'>\n<tr>\n";
             while (@grp) {
                 $edit .= '<td>'. (shift @grp) . '</td>';
                 if (! --$col && @grp) {
                    $edit .= "</tr>\n<tr>";
                    $col = 5;
                 }
             }
             $edit .= "</tr>\n</table>";
         }
     }
 }

 if (exists $RunTaskNow{$name} && $RunTaskNow{$name} && $qs{$name}) {
   ${$name} = '';
   $Config{$name} = '';
   $qs{$name} = '';
   $value = '';
 }
 my $style;
 if (! $rootlogin && ($name eq 'AdminUserFile' ||
      $name eq 'webAdminPassword' ||
      $name eq 'adminusersdb' ||
      exists $cryptConfigVars{$name} ||
      ! &canUserDo($user,'cfg',$name)))
 {
     $name = 'AD' . $name;
     $value = 'n/a';
     return  "<a name=\"$name\"></a><input name=\"$name\" type=\"hidden\" value=\"$value\">\n"  if $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"};
     $edit = '' ;
     $display = 'readonly';
     $cfgname = $EnableInternalNamesInDesc?"($name)":'';
     $style = 'style="background:#eee none; color:#222; font-style: italic"';
     $description = '';
     $Error = "<span class=\"negative\"><b>*** access denied ***</b></span><br />";
 }
 $edit = '' if(! $rootlogin && ! &canUserDo($user,'action','edit'));
 my $type = ($name eq 'SSLPKPassword') ? 'type="password"' : '' ;
 # get rid of google autofill
 #$name=~s/(e)(mail)/$1_$2/gio;
 if ($mobile) {
     if ($description =~ s/^(.+?[\.!:])((?: |\<br).*)$/$1/ois) {
         my $text = $2;
         my @inputs = $text =~ /(\<input[^\>]+\/\>)/goi;
         if (@inputs) {
             $description .= '<br />' . join('&nbsp;',@inputs);
         }
     }
 }
 return "<a name=\"$name\"></a>
 <div class=\"shadow\">
  <div class=\"option\">
   <div class=\"optionTitle$cssoption\">$nicename $cfgname</div>
   <div class=\"optionValue\">
    <input name=\"$name\" $type $display $style size=\"$size\" value=\"$value\" onfocus=\"setAnchor('$name');return false;\"/>
    $edit<br />
    $Error
    $description\n
   </div>
  </div>
  &nbsp;
 </div>";

}
