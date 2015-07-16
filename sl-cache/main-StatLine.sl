#line 1 "sub main::StatLine"
package main; sub StatLine {
    our ($l1,$l2,$l3) = @_;
    $l1->{text} = 0 unless $l1->{text};
    $l2->{text} = 0 unless $l2->{text};
    $l3->{text} = 0 unless $l3->{text};
    my $sc;
    if ($l1->{stat}) {
        if ($l1->{stat} !~ s/^#//o)
        {
            if ($l1->{stat} =~ s/^;//o) {
                $ScoreStats{$l1->{stat}} = 0 unless $ScoreStats{$l1->{stat}};
                $sc = 'score';
            } else {
                $Stats{$l1->{stat}} = 0 unless $Stats{$l1->{stat}};
                $sc = 'stat';
            }
        }
        if ($CreateMIB) {
            if ($sc eq 'score') {
                $ScoreStatText{$l1->{stat}} = $l1->{text};
                $ScoreStatText{$l1->{stat}} =~ s/\&nbsp;//og;
                $ScoreStatText{$l1->{stat}} =~ s/<a href.+?">([^<>]+)<\/a>/$1/goi;
            } else {
                $StatText{$l1->{stat}} = $l1->{text};
                $StatText{$l1->{stat}} =~ s/\&nbsp;//og;
                $StatText{$l1->{stat}} =~ s/<a href.+?">([^<>]+)<\/a>/$1/goi;
            }
        }
    }
    my $stat = delete $l1->{stat};
    my $noshow = delete $l1->{noshow};

    my $l2bar;
    if (exists $l2->{min}) {
        my $val = 0;
        if ($l2->{max} && $l2->{max} != $l2->{min}) {
            $val = int(80 * ($l2->{text} - $l2->{min}) / ($l2->{max} - $l2->{min}));
        }
        my $color = 'blue';
        $color = 'green' if $l2->{class} =~ /positive/o;
        $color = 'red'  if $l2->{class} =~ /negative/o;
        $l2bar = <<EOT;
<div style="width: $val\%; height: 10px; border: 1px solid #ccc; margin: 2px 5px 2px 0; padding: 1px; float: left; background: $color;"></div>
EOT
        delete $l2->{max};
        delete $l2->{min};
    }
    my $l3bar;
    if (exists $l3->{min}) {
        my $val = 0;
        if ($l3->{max} && $l3->{max} != $l3->{min}) {
            $val = int(80 * ($l3->{text} - $l3->{min}) / ($l3->{max} - $l3->{min}));
        }
        my $color = 'blue';
        $color = 'green' if $l3->{class} =~ /positive/o;
        $color = 'red'  if $l3->{class} =~ /negative/o;
        $l3bar = <<EOT;
<div style="width: $val\%; height: 10px; border: 1px solid #ccc; margin: 2px 5px 2px 0; padding: 1px; float: left; background: $color;"></div>
EOT
        delete $l3->{max};
        delete $l3->{min};
    }
    my $glink;
    if ($CanUseASSP_SVG && $sc && $stat && ! $noshow) {
        my $text = $l1->{text};
        $text =~ s/\s*:\s*$//o;
        $text =~ s/\&nbsp;?//og;
        $text = encHTMLent($text);
        $glink = " onclick=\"window.open('./statgraph?stattype=$sc&stat=$stat&name=$text');\"";
    }
    my $ret = <<EOT;
          <tr$glink>
            <td l1-prop>
              $l1->{text}
            </td>
            <td l2-prop>
              $l2bar$l2->{text}
            </td>
            <td l3-prop>
              $l3bar$l3->{text}
            </td>
          </tr>
EOT
    foreach my $l ('l1','l2','l3') {
        delete ${$l}->{text};
        my $tdp;
        foreach (sort keys %{${$l}}) {
            $tdp .= $_ . '="'.${${$l}}{$_}.'" ';
        }
        $ret =~ s/$l-prop/$tdp/;
    }
    return $noshow ? '' : $ret;
}
