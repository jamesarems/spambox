#line 1 "sub main::niceLink"
package main; sub niceLink {
    my $c = shift;
    my $i = 0;
    my %v = ();
    while ($c =~ s/(\$[a-zA-Z][a-zA-Z0-9_{}\[\]\-\>]+)/\[\%\%\%\%\%\]/o) {
        my $var = $1;
        $v{$i} = eval($var);
        $v{$i} = $var unless defined $v{$i};
        $i++;
    }
    $i = 0;
    while ($c =~ s/\[\%\%\%\%\%\]/$v{$i}/o) {$i++}
    my $newline;
    foreach my $word (split(/ /o,$c)) {
         my $orgword = $word;
         $word =~ s/[^a-zA-Z0-9_]//go;
         if (exists $Config{$word} && ($rootlogin || ! $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"})) {
              my $alt = $ConfigNice{$word};
              my $value = encodeHTMLEntities($ConfigListBox{$word});
              $value =~ s/'|"|\n//go;
              $value =~ s/\\/\\\\/go;
              $value = '&nbsp;' unless $value;
              $value = 'ENCRYPTED' if exists $cryptConfigVars{$word};
              my $default = exists $cryptConfigVars{$word} && $word ne 'webAdminPassword'? 'ENCRYPTED' : $ConfigDefault{$word};
              my $subst = "<a href=\"./#$word\" style=\"color:#684f00\" onmousedown=\"showDisp('$ConfigPos{$word}');gotoAnchor('$word');return false;\" onmouseover=\"window.status='$alt'; showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\' bgcolor=lightyellow><tr><td>config var:</td><td>$word</td></tr><tr><td>description:</td><td>$alt</td></tr><tr><td>current value:</td><td>$value</td></tr><tr><td>default value:</td><td>$default</td></tr></table>', this, event, '450px', '1'); return true;\" onmouseout=\"window.status='';return true;\">$word</a>" ;
              $orgword =~ s/$word/$subst/;
         } elsif (exists $tempDBvars{$word} && ($rootlogin || &canUserDo($WebIP{$ActWebSess}->{user},'action','editinternals')) ) {
              my $subst = "<a href=\"#\" onclick=\"return popFileEditor(\'DB-$word\',\'1h\');\">$word</a>";
              $orgword =~ s/$word/$subst/;
         }
         $newline .= " $orgword";
    }
    return $newline;
}
