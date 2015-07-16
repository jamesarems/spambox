#line 1 "sub main::syncShowGUI"
package main; sub syncShowGUI {
    my $name = shift;
    return '' unless &syncCanSync();
    my $syncserver = $ConfigSync{$name}->{sync_server};
    return '' if ($WebIP{$ActWebSess}->{user} ne 'root' && ! &canUserDo($WebIP{$ActWebSess}->{user},'action','syncedit'));
    return '' if ($WebIP{$ActWebSess}->{user} ne 'root' && ! &canUserDo($WebIP{$ActWebSess}->{user},'cfg',$name));

    if ($ConfigSync{$name}->{sync_cfg} == -1) {
        return '';
    } elsif ($ConfigSync{$name}->{sync_cfg} == 0) {

        return $syncShowGUIDetails
          ? '&nbsp;&nbsp;<a href="javascript:void(0);" onclick="javascript:popSyncEditor(\''.$name.'\');" >(shareable)</a>'
          : '<a href="javascript:void(0);" onclick="javascript:popSyncEditor(\''.$name.'\');" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>&nbsp;&nbsp;shareable</td></tr></table>\', this, event, \'90px\', \'1\'); return true;"><b><font color=\'black\'>&nbsp;&nbsp;&bull;</font></b></a>';
    } else {
        my $stat = &syncGetStatus($name);
        return '' if $stat == -1;
        return ($syncShowGUIDetails
          ? '&nbsp;&nbsp;<a href="javascript:void(0);" onclick="javascript:popSyncEditor(\''.$name.'\');" >(shareable)</a>'
          : '<a href="javascript:void(0);" onclick="javascript:popSyncEditor(\''.$name.'\');" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>&nbsp;&nbsp;shareable</td></tr></table>\', this, event, \'90px\', \'1\'); return true;"><b><font color=\'black\'>&nbsp;&nbsp;&bull;</font></b></a>') if $stat == 0;
        my $ret = '&nbsp;&nbsp;(<span class="negative">shared: </span>';
        $ret = '&nbsp;&nbsp;(<span class="positive">shared: </span>' if ($stat == 2);
        my $shared = 0;
        while (my($k,$v) = each %{$syncserver}) {
            $k =~ s/:[^:]+$//o;
            if ($v == 0) {
                $ret .= "$k not shared, ";
            } elsif ($v == 1) {
                $ret .= "<span class=\"negative\">$k out of sync, </span>";
                $shared = 1;
            } elsif ($v == 2 or $v == 4) {
                $ret .= "<span class=\"positive\">$k in sync, </span>";
                $shared = 1;
            } elsif ($v == 3) {
                $ret .= "<span class=\"positive\">$k local slave mode, </span>";
                $shared = 1;
            }
        }
        $ret .= ')';
        $ret =~ s/(sync|mode), ([^\)]+?\))$/$1$2/o;
        if ($syncShowGUIDetails) {
            return '<a href="javascript:void(0);" onclick="javascript:popSyncEditor(\''.$name.'\');">'.$ret.'</a>';
        }
        my $color = ($ret =~ /negative/o) ? 'red' : 'green';
        $color = 'black' unless $shared;
        $ret =~ s/"/\\'/go;
        $ret =~ s/\(|\)//go;
        $ret =~ s/, /\<br \/\>/go;
        $ret =~ s/: /:\<hr\>/go;
        return '<a href="javascript:void(0);" onclick="javascript:popSyncEditor(\''.$name.'\');" onmouseover="showhint(\'<table BORDER CELLSPACING=0 CELLPADDING=4 WIDTH=\\\'100%\\\'><tr><td>'.$ret.'</td></tr></table>\', this, event, \'220px\', \'1\'); return true;"><b><font color=\''. $color .'\'>&nbsp;&nbsp;&bull;</font></b></a>';
    }
}
