#line 1 "sub main::ConfigConfidencePlot"
package main; sub ConfigConfidencePlot {
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
    $out .= "\n<head>\n<title>confidence distribution graphic</title>\n";
    $out .= "</head><body>\n";

    unloadNameSpace("ASSP_SVG") if $ASSP_FC::TEST;
    eval('use ASSP_SVG; 1;') or return $out."<h1>ERROR: can not load lib/ASSP_SVG.pm - $@</h1></body></html>";
    open(my $F, '<', "$base/images/svg.js") or return $out."<h1>ERROR: can not open $base/images/svg.js - $!</h1></body></html>";
    binmode $F;
    my $Jscript = join('',<$F>);
    close $F;
    if ($Jscript !~ m!^\s*//\s*version\s*(\d+\.\d+)! || $1 lt '1.03') {
        return $out."<h1>ERROR: $base/images/svg.js has version '$1' - required is at least version '1.03'</h1></body></html>";
    }
    unless ($baysConf) {
        return $out."<h1>ERROR: set <a href=\"./#baysConf\">baysConf</a> to a value &gt; zero first</h1></body></html>";
    }
    unless ($enableGraphStats) {
        return $out."<h1>ERROR: enable <a href=\"./#enableGraphStats\">enableGraphStats</a> first</h1></body></html>";
    }
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
    $qs{stattype} ||= 'confidence';
    $qs{stattype} = lc($qs{stattype});
    my $statfile = lc($qs{stattype}).'GraphStats';
    my $fy = substr($from,0,4);
    my $fm = substr($from,5,2);
    my $ty = substr($to,0,4);
    my $tm = substr($to,5,2);
    my $values = {'bayesconf_ham' => {},'bayesconf_spam' => {},'hmmconf_ham' => {},'hmmconf_spam' => {}};
    my ($minval, $maxval) = ($baysConf/100,$baysConf*100);  # min and max confidence in graph (exp 1 to 5)
    unless ($maxval) {
        return $out."<h1>ERROR: <a href=\"./#baysConf\">baysConf</a> is set to zero</h1></body></html>";
    }
    $out = '';
    my $maxlog = log($maxval);   # exponent for the max confidence graph
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
                             # date         conf name       conf value  count
                next unless /([0-9_:-]+) ([a-zA-Z0-9_-]+): (\d\.\d+): (\d+)/o;
                next unless $3;
                my $t = $1;
                next if $t lt $from;     # date is too less for range
                last if $t gt $to;       # date is too high for range - all next will also
                my $val = log($3);       # the exponent for the conf value
                my $x = $val/$maxlog;    # calculate the exponent
                if ($x < 1) {
                    $values->{$2}->{'high'} += $4;
                    next;
                } elsif ($x > 5){        # ignore out of range exponents
                    $values->{$2}->{'low'} += $4;
                    next;
                } else {
                    $x = sprintf("%.5f",(6 - $x));  # calculate the revers graph exponent
                    $values->{$2}->{$x} += $4;
                }
            }
            close $F;
        }
    }
    
    my $name = $qs{name};
    $name ||= 'Bayesian and Hidden-Markov-Model SPAM and HAM confidence distribution';
    my @confp;
    my $plot;
    open( $F,'<',"$base/images/confidence.gplot") or return "ERROR: can not open $base/images/confidence.gplot - $!";
    while (<$F>) {
        next if m/^\s*#/o;
        s/\r|\n//go;
        s/<SIZE>/$size/o;
        s/<L1>/$name/o;
        s/<BH>/Bayesian HAM/o;
        s/<BS>/Bayesian SPAM/o;
        s/<HH>/HMM HAM/o;
        s/<HS>/HMM SPAM/o;
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
    $out .= "\n<head>\n<title>Bayesian and HMM confidence distribution graphic</title>\n";

    $out .= '<meta name="viewport" content="initial-scale=1, maximum-scale=1"/>'."\n";

    $out .= '<script type="text/javascript">'."\n";
    $out .= $Jscript.'</script>'."\n";

    $out .=  "</head>\n<body name=\"$stat\">\n";

    my $tf = $from;
    $tf =~ s/_/ /go;
    my $tt = $to;
    $tt =~ s/_/ /go;
    $size = $mobile ? 'style="width:500px;"' : 'style="width:850px;"';

    $out .= "<div id=\"form\" $size>".'<form name="ASSPgraph" id="ASSPgraph" action="" method="post"><center>
    from: <input name="from" size="20" value="'.$tf.'">
    to: <input name="to" size="20" value="'.$tt.'">
    <input name="stattype" type="hidden" value="'.$qs{stattype}.'">
    <input name="stat" type="hidden" value="'.$qs{stat}.'">
    <input name="name" type="hidden" value="'.$qs{name}.'">
    &nbsp;&nbsp;<input name="theButton" type="submit" value="change time range" />
    </center></form><hr></div>'."\n";

    $size = $mobile ? 'style="width:500px; height:350px;"' : 'style="width:850px; height:500px;"';
    $out .= "<div id=\"svggraphic\" $size>\n";
    $out .= eval{ASSP_SVG::SVG_render_confidence($stat,1,5,\@confp,$values,$plot,"$base/images");};
    $out .= $@ if $@;
    $out .= "</div>\n";

    $out .= '<script type="text/javascript">'."\n";
    $out .= "formdiv = document.getElementById('form');\n";
    $out .= "confTop = $maxval;\n";
    $out .= "confRev = 5;\n";
    $out .= '</script>'."\n";
    $out .= "</body>\n</html>";

    return $out;
}
