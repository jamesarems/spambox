#line 1 "sub main::ConfigStatsPlot"
package main; sub ConfigStatsPlot {
    # must pass by ref
    my ( $href, $qsref ) = @_;
    my $head;
    $head = $$href if $href;
    my $qs;
    $qs = $$qsref if $qsref;

    my $out = "HTTP/1.1 200 OK
Content-type: text/html

";
    $out .= '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'."\n";
    $out .= '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" '.
                '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'."\n";
    $out .= '<html xmlns="http://www.w3.org/1999/xhtml">';
    $out .= "\n<head>\n<title>statistic graphic</title>\n";
    $out .= "</head><body>\n";

    unloadNameSpace("SPAMBOX_SVG") if $SPAMBOX_FC::TEST;
    eval('use SPAMBOX_SVG; 1;') or return $out."<h1>ERROR: can not load lib/SPAMBOX_SVG.pm - $@</h1></body></html>";
    open(my $F, '<', "$base/images/svg.js") or return $out."<h1>ERROR: can not open $base/images/svg.js - $!</h1></body></html>";
    binmode $F;
    my $Jscript = join('',<$F>);
    close $F;
    $out = '';
    my ($today,$now) = split(/ /o,timestring('','','YYYY-MM-DD hh:mm:ss'));
    my $starth = substr($now,0,2).':00:00';
    my $yesterday = timestring((time-84600),'d','YYYY-MM-DD');
    my $stat = $qs{stat};
    my $size = $mobile ? '480,320' : '800,400';
    $qs{from} =~ s/^\s+//o;
    $qs{from} =~ s/\s+$//o;
    $qs{from} =~ s/^
          (\d{4}|\d{2})
          [\-\.]?
          (\d{1,2})
          [\-\.]?
          (\d{1,2})
          [^\d]+
          (\d{1,2})
          [\-\.:]?
          (\d{1,2})?
          [\-\.:]?
          (\d{1,2})?
                  $/
          ex($1,4).'-'.ex($2).'-'.ex($3).'_'.ex($4).':'.ex($5).':'.ex($6)
                  /oex if $qs{from};
    my $from = $qs{from} || $yesterday.'_'.$starth;
    $qs{to} =~ s/^\s+//o;
    $qs{to} =~ s/\s+$//o;
    $qs{to} =~  s/^
          (\d{4}|\d{2})
          [\-\.]?
          (\d{1,2})
          [\-\.]?
          (\d{1,2})
          [^\d]+
          (\d{1,2})
          [\-\.:]?
          (\d{1,2})?
          [\-\.:]?
          (\d{1,2})?
                  $/
          ex($1,4).'-'.ex($2).'-'.ex($3).'_'.ex($4).':'.ex($5).':'.ex($6)
                  /oex if $qs{to};
    my $to = $qs{to} || $today.'_'.$now;
    $to = $today.'_'.$now if $to gt ($today.'_'.$now);
    if ($to le $from) {
        $from = $yesterday.'_'.$starth;
        $to = $today.'_'.$now;
    }
    my $dp;
    $qs{stattype} ||= 'stat';
    $qs{stattype} = lc($qs{stattype});
    my $statfile = lc($qs{stattype}).'GraphStats';
    my $xstep = (SPAMBOX_SVG::SVG_time_to_sec($to) - SPAMBOX_SVG::SVG_time_to_sec($from))/substr($size,0,3);
    my $fy = substr($from,0,4);
    my $fm = substr($from,5,2);
    my $ty = substr($to,0,4);
    my $tm = substr($to,5,2);
    my $nextstep = SPAMBOX_SVG::SVG_time_to_sec($from);
    my $firststep;
    for my $yy ($fy ... $ty) {
        my $ttm = ($yy == $ty) ? $tm : 12;
        my $ffm = ($yy == $fy) ? $fm : 1;
        for my $mm ($ffm ... $ttm) {
            $yy = sprintf("%04d",$yy);
            $mm = sprintf("%02d",$mm);
            open(my $F,'<',"$base/logs/$statfile-$yy-$mm.txt") or do {
                mlog(0,"warning: can not open $base/logs/$statfile-$yy-$mm.txt - $!") && next;};
            binmode $F;
            while (<$F>) {
                next unless s/(.+)$stat: (.+)/$1$2/;
                my $t = $1;
                chop $t;
                $firststep = "$from $2\n" unless $dp;
                next if $t lt $from;
                last if $t gt $to;
                if ($firststep) {
                    $dp = $firststep;
                    $firststep = undef;
                }
                $t = SPAMBOX_SVG::SVG_time_to_sec($t);
                next if ($nextstep > $t);
                $nextstep = int($t + $xstep - $t % $xstep);
                $dp .= $_;
            }
            close $F;
        }
    }
    $dp.= "#\n";

    my $name = $qs{name};
    my @confp;
    my $plot;
    open( $F,'<',"$base/images/stat.gplot") or return "ERROR: can not open $base/images/stat.gplot - $!";
    while (<$F>) {
        next if m/^\s*#/o;
        s/\r|\n//go;
        s/<SIZE>/$size/o;
        s/<L1>/$name/o;
        s/<L2>/$stat count/o;
        if (s/\\\s*$//o) {$plot .= $_; next;}
        next unless m/^\s*set/io;
        push @confp, "$_\n";
    }
    close $F;

    $out .= "HTTP/1.1 200 OK
Content-type: text/html

";
    $out .= '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'."\n";
    $out .= '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" '.
                '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'."\n";
    $out .= '<html xmlns="http://www.w3.org/1999/xhtml">';
    $out .= "\n<head>\n<title>$stat statistic graphic</title>\n";

    $out .= '<meta name="viewport" content="initial-scale=1, maximum-scale=1"/>'."\n";

    $out .= '<script type="text/javascript">'."\n";
    $out .= $Jscript.'</script>'."\n";

    $out .=  "</head>\n<body name=\"$stat\">\n";

    my $tf = $from;
    $tf =~ s/_/ /go;
    my $tt = $to;
    $tt =~ s/_/ /go;
    $size = $mobile ? 'style="width:500px;"' : 'style="width:850px;"';

    $out .= "<div id=\"form\" $size>".'<form name="SPAMBOXgraph" id="SPAMBOXgraph" action="" method="post"><center>
    from: <input name="from" size="20" value="'.$tf.'">
    to: <input name="to" size="20" value="'.$tt.'">
    <input name="stattype" type="hidden" value="'.$qs{stattype}.'">
    <input name="stat" type="hidden" value="'.$qs{stat}.'">
    <input name="name" type="hidden" value="'.$qs{name}.'">
    &nbsp;&nbsp;<input name="theButton" type="submit" value="change time range" />
    </center></form><hr></div>'."\n";

    $size = $mobile ? 'style="width:500px; height:350px;"' : 'style="width:850px; height:500px;"';
    $out .= "<div id=\"svggraphic\" $size>\n";
    $out .= eval{SPAMBOX_SVG::SVG_render($stat,$from,$to,\@confp,\$dp,$plot,"$base/images");};
    $out .= "</div>\n";

    $out .= '<script type="text/javascript">'."\n";
    $out .= "formdiv = document.getElementById('form');\n";
    $out .= '</script>'."\n";
    $out .= "</body>\n</html>";

    return $out;
}
