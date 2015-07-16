#line 1 "sub main::syncedit"
package main; sub syncedit {
    my $name = $qs{cfgparm};
    return 'incomplete request' unless $name;
    return 'synchronization not allowed for ' . $name if exists $neverShareCFG{$name};
    return 'no such configuration parameter ' . $name if ! exists $Config{$name};
    my %sync_server;
    my @syncServer = (split(/\|/o,$syncServer));
    my %syncMode = (0 => 'no sync', 1 => 'out of sync', 2 => 'in sync', 3 => 'as slave', '' => 'remove');
    my $msg;
    my ($fn) = $syncConfigFile =~ /^ *file:(.+)$/io;
    while (my ($k,$v) = each %qs) {
        next if $k !~ /^sync_server(\d+)/o;
        $v =~ s/\s//go;
        next unless $v;
        $sync_server{$v} = $qs{'val'.$1} if $qs{'val'.$1} ne '';
    }
    my $enable_sync = $qs{enable} ? 1 : 0;
    if ($qs{theButton}){
        $ConfigSync{$name}->{sync_cfg} = $enable_sync;
        $ConfigSync{$name}->{sync_server} = &share({});
        my $i = 0;
        while (my ($k,$v) = each %sync_server) {
            $ConfigSync{$name}->{sync_server}->{$k} = $v;
            $i++;
        }
        unless ($i) {
            $ConfigSync{$name}->{sync_cfg} = 0;
            $msg .= "<hr>no sync peer defined for $name - synchronization is now disabled for $name<hr>\n";
        }
        if (&syncWriteConfig()) {
            $msg .= "<hr><span class=\"positive\">successfully saved changes to file $fn</span><hr>\n";
            $NextSyncConfig = time - 1;
        }
    }
    my $server = $ConfigSync{$name}->{sync_server};
    my $checked = $ConfigSync{$name}->{sync_cfg} ? 'checked="checked"' : '';
    $msg .= "<hr>resulting line in file $fn:<br /><br />$name:=$ConfigSync{$name}->{sync_cfg}";
    while (my ($k,$v) = each %{$server}) {
        $msg .= ",$k=$v";
    }
    $msg .= '<br /><hr>';
    
    my $s = '<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH="100%" >';
    $s .= '<tr><td>enable/disable synchronization for '.$name.' : ';
    $s .= "<input type=\"checkbox\" name=\"enable\" value=\"1\" $checked /></td></tr></table><hr>\n";
    $s .= '<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH="100%" >'."\n";
    my $i = 0;
    foreach my $k (@syncServer) {
        $i++;

        $s .= "<tr><td>&nbsp;&nbsp;peer : ";
        $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"sync_server$i\">\n";
        my $sel = '';
        $sel = "selected=\"selected\"" if exists $server->{$k};
        $s .= "<option $sel value=\"$k\">$k</option>";
        $s .= "</select></span></td>\n";

        $s .= "<td>&nbsp;&nbsp;mode/status : ";
        $s .= "<span style=\"z-Index:100;\"><select size=\"1\" name=\"val$i\">\n";
        for (0..3,'') {
            my $sel = '';
            $sel = "selected=\"selected\"" if $_ eq $server->{$k};
            my $s1 = ($_ ne '') ? "($_)" : '';
            $s .= "<option $sel value=\"$_\">$syncMode{$_} $s1</option>\n";
        }
        $s .= "</select></span></td></tr>";
    }
    $s .= '</table>'."\n<hr>\n";
    $s .= '<input type="hidden" name="cfgparm" value="'.$name.'" />';
    $s .= '<input type="submit" name="theButton" value="Save Changes" />&nbsp;&nbsp;';
    $s .= '<input type="button" value="Close" onclick="javascript:window.close();"/>';
    $s .= $msg;
return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage SPAMBOX SyncConfig ($myName - $name)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
</head>
<body onmouseover="this.focus();" >
    <div class="content">
      <form action="" method="post">
        $s
      </form>
    </div>
</body>
</html>

EOT
}
