#line 1 "sub main::listbox"
package main; sub listbox {
	
	my ( $name, $nicename, $values, $func, $default, $valid, $onchange, $description, $cssoption, $note ,$lngNice,$lngDesc ) = @_;
    $values = $values->() if ref $values;
	my $Error = checkUpdate( $name, $valid, $onchange,$nicename);

    my $user = $WebIP{$ActWebSess}->{user};
    if (exists $WebIP{$ActWebSess}->{lng}->{$lngNice}) {
        $nicename = $WebIP{$ActWebSess}->{lng}->{$lngNice};
    }
    if (exists $WebIP{$ActWebSess}->{lng}->{$lngDesc}) {
        $description = $WebIP{$ActWebSess}->{lng}->{$lngDesc};
    }
    $description = &niceLink($description);
    my $display = '';
    my $options;
    my $hdefault;
    my $conf = $Config{$name};
    if (exists $ConfigAdd{$name}) {
        $conf = $ConfigAdd{$name};
    }
	foreach my $opt ( split( /\|/o, $values ) ) {
		my ( $v, $d ) = split( /:/o, $opt, 2 );
		$d = $v unless $d;
		Encode::from_to($d,'ISO-8859-1','UTF-8') if ($d && ! Encode::is_utf8($d));
		if ( $conf eq $v ) {
			$options .= "<option selected=\"selected\" value=\"$v\">$d</option>";
		} else {
			$options .= "<option value=\"$v\">$d</option>";
		}
        $hdefault = $d if ( $default eq $v );
	}
    my $color = ($conf eq $default) ? '' : 'style="color:#8181F7;"';

    my $cfgname = $EnableInternalNamesInDesc?"<a href=\"javascript:void(0);\"$color onmousedown=\"document.forms['SPAMBOXconfig'].$name.value='$default';setAnchor('$name');return false;\" onmouseover=\"showhint('<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\'100%\\'><tr><td>click to reset<br />to default value</td><td>$hdefault</td></tr></table>', this, event, '450px', '1'); return true;\" onmouseout=\"window.status='';return true;\"><i>($name)</i></a>":'';
    $cfgname = "($name)" if $EnableInternalNamesInDesc && $mobile;
    $cfgname .= syncShowGUI($name);
    if (! $rootlogin && (exists $cryptConfigVars{$name} ||
         ! &canUserDo($user,'cfg',$name)))
    {
        $name = 'AD' . $name;
        return  "<a name=\"$name\"></a><input name=\"$name\" type=\"hidden\" value=\"0\">\n"  if $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.hidDisabled"};
        $display = 'disabled';
        $cfgname = $EnableInternalNamesInDesc?"($name)":'';
        $description = '';
        $options =~ s/selected=\"selected\"//o;
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
  <div class=\"optionTitle$cssoption\">$nicename $cfgname</div>
  <div class=\"optionValue\">
  <span style=\"z-Index:100;\">
    <select $display size=\"1\" name=\"$name\" onfocus=\"setAnchor('$name');return false;\">
	 $options
	</select>
  </span>
  $edit
  <br />\n$Error$description
  </div>
 </div>
 &nbsp;
 </div>";
}
