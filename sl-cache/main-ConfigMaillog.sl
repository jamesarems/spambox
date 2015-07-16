#line 1 "sub main::ConfigMaillog"
package main; sub ConfigMaillog {
 my $stime = time;
 my $loopcount;
 my $loopcheck = 10;
 my $maxsearchsec = 60;
 my $maxsearchtime = $stime + $maxsearchsec;
 my $pat=$qs{search};
 my $matches=0;
 my $currWrap;
 if (exists $qs{wrap}) {
    $currWrap = $qs{wrap};
 } elsif ($WebIP{$ActWebSess}->{user} ne 'root') {
    $currWrap = $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.wrap"};
 } elsif ( ! $currWrap) {
    $currWrap = 2;
 }
 $currWrap = 2 unless $currWrap;
 $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.wrap"} = $currWrap if $WebIP{$ActWebSess}->{user} ne 'root';
 &niceConfig() if ($qs{autorefresh} ne 'Auto' && !$qs{filesonly});
 
 my $colorLines;
 if (exists $qs{color}) {
    $colorLines = $qs{color};
 } elsif ($WebIP{$ActWebSess}->{user} ne 'root') {
    $colorLines = $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.color"};
 } elsif ( ! $colorLines) {
    $colorLines = 1;
 }
 $colorLines = 1 unless $colorLines;
 $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.color"} = $colorLines if $WebIP{$ActWebSess}->{user} ne 'root';

 my $order;
 if (exists $qs{order}) {
    $order = $qs{order};
 } elsif ($WebIP{$ActWebSess}->{user} ne 'root') {
    $order = $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.order"};
 } elsif ( ! $order) {
    $order = 0;
 }
 $order = 0 unless $order;
 $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.order"} = $order if $WebIP{$ActWebSess}->{user} ne 'root';

 my $savTailByte = $MaillogTailBytes;
 my $currTailByte; $currTailByte = $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.TailByte"} if $WebIP{$ActWebSess}->{user} ne 'root';
 ($currTailByte) = $1 if $qs{tailbyte}=~/(\d+)/;
 $currTailByte = $MaillogTailBytes if ($MaillogTailBytes>0 && (! $currTailByte || $currTailByte<160));
 $currTailByte = 2000 unless $currTailByte;
 $MaillogTailBytes = $currTailByte;
 $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.TailByte"} = $currTailByte if $WebIP{$ActWebSess}->{user} ne 'root';

 my $orgpat = $pat;
 my $filesonly=$qs{filesonly};
 my $autoJS = '';
 my $autoButton = 'Auto';
 my $CMheaders = \$headers;
 my $content = 'class="content"';
 my $logstyle = '';
 my $display = '';
 $pat = $qs{search} = '' if $qs{autorefresh} eq 'Stop';
 if ($qs{autorefresh} eq 'Auto') {
     $pat = '';
     $qs{filesonly}= $filesonly = '';
     $qs{nohighlight} = 1;
     $autoButton = 'Stop';
     $CMheaders = \'';
     $display = 'style="display:none"';
     $content = 'class="content" style="margin: 0 0 0 0;"';
     $logstyle = 'style="border-width: 4px 4px 4px 4px; border-color: #6699cc; border-style: solid;"';

     $autoJS = '
<script type="text/javascript">
 Timer=setTimeout("newTimer();",'. $refreshWait .'000);
 var Run = 1;
 function noop () {}
 function tStart () {
    Run = 1;
 }
 function tStop () {
    Run = 0;
    Timer=setTimeout("noop();", 1000);
 }
 function newTimer() {
   if (Run == 1) {location.reload(true)};
   Timer=setTimeout("newTimer();",'. $refreshWait .'000);
 }
</script>
';
#  <meta http-equiv=\"refresh\" content=\"$refreshWait;url=/maillog?search=\&wrap=$qs{wrap}\&color=$colorLines\&autorefresh=Auto\&files=$qs{files}\&limit=$qs{limit}\&nohighlight=$qs{nohighlight}\&nocontext=$qs{nocontext}\&tailbyte=$qs{tailbyte}\&size=$qs{size}\&order=$qs{order}\" />

     $CMheaders = \"<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head>
  <meta http-equiv=\"content-type\" content=\"application/xhtml+xml; charset=utf-8\" />
  <title>$currentPage SPAMBOX ($myName) Host: $localhostname @ $localhostip</title>
  <link rel=\"stylesheet\" href=\"get?file=images/assp.css\" type=\"text/css\" />
  <link rel=\"shortcut icon\" href=\"get?file=images/favicon.ico\" />
$autoJS
</head>
<body onfocus=\"tStart();\" onblur=\"tStop();\"><a name=\"MlTop\"></a>
";
 }
 my $rspamlog = "rebuild_error/$spamlog";
 my $rnotspamlog = "rebuild_error/$notspamlog";
 my $rcorrectedspam = "rebuild_error/$correctedspam";
 my $rcorrectednotspam = "rebuild_error/$correctednotspam";
 my $s='';
 my $res='';
 my $base = $base;
 $base =~ s/([^\\])\\([^\\])/$1\\\\$2/go;
 # calculate indent
 my $m = &timestring().' ';
 my $resetpat;
 my $reportExt = $maillogExt;
 if(!$pat && $filesonly) {
     $resetpat = 1;
     $pat = $maillogExt;
 }
 if(!$pat) {
  my $TailBytes = ($qs{autorefresh} eq 'Auto' && $MaillogTailBytes > 2000) ? 2000 : $MaillogTailBytes;
  if ($qs{autorefresh} eq 'Auto') {
      my $sl; $sl = $1 if $qs{search} =~ /(\d+)/o;
      $sl = $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.autolines"} if $sl == '' && $WebIP{$ActWebSess}->{user} ne 'root';
      my $al = $sl ? 33 - $sl : $currWrap ? 10 : 0;
      $al = 0 if $al < 0;
      $al = 32 if $al > 32;
      $AdminUsersRight{"$WebIP{$ActWebSess}->{user}.user.autolines"} = $sl if $WebIP{$ActWebSess}->{user} ne 'root';
      for (my $i = $al; $i < 33; $i++) {
          $s .= $RealTimeLog[$i];
      }
  } else {
      open(my $CML,'<',"$base/$logfile");
      seek($CML,-$TailBytes,2) || seek($CML,0,0);
      local $/;
      $s=<$CML>;
      close $CML;
  }
  $s=encodeHTMLEntities($s) if $s;
  $s=~s/([^\\])?\\([^\\])?/$1\\\\$2/gso;
   my @sary=map{$_."\n" if $_;} split(/\r?\n|\r/o,$s);
   shift @sary if ($qs{autorefresh} ne 'Auto');
   my @rary;
   $matches=0;
   while (@sary) {
    $_ = shift @sary;
    @sary = () if time > $maxsearchtime;
    s/\\x\{\d+\}//g;
    if ($qs{autorefresh} ne 'Auto') {
     $maxsearchtime += &MainLoop1(0) unless ++$loopcount % $loopcheck;
     if (/(.*)?(\Q$base\E\/(($spamlog|$discarded|$notspamlog|$incomingOkMail|$viruslog|$correctedspam|$correctednotspam|$resendmail|$rspamlog|$rnotspamlog|$rcorrectedspam|$rcorrectednotspam)\/\S[^\r\n\t]*?(?:\Q$maillogExt\E|\Q$reportExt\E)))(.*)/)
     {
         my $text = $1;
         my $file = $2;
         my $hfile = $3;
         my $dname = $4;
         my $text2 = $5;
         my $span = ($dname =~ /^(?:$spamlog|$discarded|$viruslog|$correctedspam|$rspamlog|$rcorrectedspam)$/) ? 'negative' : 'positive';
         $span = 'spampassed' if /\[spam passed\]/gio;
         $text =~ s/([^ ]+) +/<span style="white-space:nowrap;">$1<\/span> /go;
         $text2 =~ s/([^ ]+) +/<span style="white-space:nowrap;">$1<\/span> /go;
         if (&existFile($file)) {
           $hfile = "<span style=\"white-space:nowrap;\" onclick=\"popFileEditor('" . &normHTML($hfile) . "','m');\" class=\"" . $span . "\" onmouseover=\"fileBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=fileBG;\"><b>" . $hfile . "<\/b><\/span>";
         } else {
           $hfile =~ s/([^ ]+) +/<span style="white-space:nowrap;">$1<\/span> /go;
         }
         $text .= $hfile . $text2;
         push(@rary,'<div id="ll' . $matches .'" class="assplogline'. ($currWrap + ($matches % 2 && $colorLines)) .'">' . $text . "\n</div>");
         $matches++;
         next;
     } elsif (! $filesonly) {
         my @links;
         my @addr;
         my @ips;
         $_ = niceLink($_);
         while ($_ =~ s/(\<a href.*?<\/a\>)/XXXIIIXXX/o) {
             my $link = $1;
             $link =~ s/WIDTH=[^\d]*(\d+\%)[^ ]*/WIDTH=$1/io;
             push @links,$link;
         }
         if (&canUserDo($WebIP{$ActWebSess}->{user},'action','addraction')) {
             while ($_ =~ s/((?<!Message-ID found: ))($EmailAdrRe\@$EmailDomainRe)/$1XXXAIIIDXXX/o) {
                 push @addr ,
                    "<span style=\"white-space:nowrap;\" onclick=\"popAddressAction('"
                    . &normHTML($2)
                    . "');\" class=\"menuLevel2\" onmouseover=\"fileBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=fileBG;\"><b>"
                    . $2
                    . "<\/b><\/span>";
             }
         }
         if (&canUserDo($WebIP{$ActWebSess}->{user},'action','ipaction')) {
             while ($_ =~ s/($IPRe)([^:\d\/])/XXXiIIIpXXX$2/o) {
                 my  $ip = $1;
                 if (   $ip !~ /$IPprivate/o
                     && $ip ne $localhostip
                     && $ip !~ /$LHNRE/)
                 {
                     push @ips,
                        "<span style=\"white-space:nowrap;\" onclick=\"popIPAction('"
                        . &normHTML($ip)
                        . "');\" class=\"menuLevel2\" onmouseover=\"fileBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=fileBG;\"><b>"
                        . $ip
                        . "<\/b><\/span>";
                 } else {
                     push @ips, $ip;
                 }
             }
         }
         s/([^ ]+) +/<span style="white-space:nowrap;">$1<\/span> /go;
         if (@links) {
             s/XXXIIIXXX/shift(@links)/geo;
         }
         if (@addr) {
             s/XXXAIIIDXXX/shift(@addr)/geo;
         }
         if (@ips) {
             s/XXXiIIIpXXX/shift(@ips)/geo;
         }
     }
     if ($filesonly) {
         next;
     }
    }
    push(@rary,'<div id="ll' . $matches .'" class="assplogline'. ($currWrap + ($matches % 2 && $colorLines)) .'">' . $_ . "\n</div>");
    $matches++;
   }
   $s = join('',@rary);
   $s =~ s/"/\\"/go;
   $s =~ s/\n+<\/div>/<\/div>XXXIIIXXX/go;
   $s =~ s/\r|\n//go;
   $s =~ s/XXXIIIXXX$//o;
 } elsif ($CanSearchLogs) {
  my @sary;
  $matches=0;
  my $lines=0;
  my $files=0;
  my ($logdir, $logdirfile) = $logfile=~/^(.*[\/\\])?(.*?)$/o;
  my @logfiles1=reverse sort( Glob("$base/$logdir*$logdirfile"));
  my @logfiles;
  while (@logfiles1) {
      my $k = shift @logfiles1;
      push(@logfiles, $k) if $k !~ /b$logdirfile/;
  }
  my $maxmatches =
                $qs{limit} eq '2000' ? 2000
              : $qs{limit} eq '1000' ? 1000
              : $qs{limit} eq '100'  ? 100
              : $qs{limit} eq '10'   ? 10
              : $qs{limit} eq '1'    ? 1
              :                        0;
  my $maxlines;
  my $maxfiles;
  if ($qs{files} eq 'lines') {
      ($maxlines) = $qs{size} =~ /(\d+)/o;
      $maxlines = 10000 unless $maxlines;
      $maxfiles = 0;
  } elsif ($qs{files} eq 'files') {
      ($maxfiles) = $qs{size} =~ /(\d+)/o;
      $maxfiles = 2 unless $maxfiles;
      $maxlines = 0;
  } elsif ($qs{files} eq 'ago') {
      $maxfiles = $qs{size};
      $maxfiles =~ s/\s//go;
      $maxfiles =~ s/-/.../go;
      my @num = sort {$main::a <=> $main::b} map(eval($_),split(/,/, $maxfiles));
      @num = (1) unless $maxfiles or @num;
      my @lof = @logfiles;
      @logfiles = ();
      foreach (@num) {
          push(@logfiles , $lof[$_ - 1]) if $_ > 0 && $lof[$_ - 1];
      }
      push(@logfiles,$lof[0]) unless @logfiles;
      $maxlines = 0;
  } else {
      $maxlines = 0;
      $maxfiles = 0;
  }
  my $logf=File::ReadBackwards->new(shift(@logfiles),'(?:\r?\n|\r)',1); # line terminator regex
  if ($logf) {
   $files++;

#   $pat = &encHTMLent(\$pat);
#   $pat = encodeHTMLEntities($pat);
#   $pat=~s/([^\\])?\\([^\\])?/$1\\\\$2/gso;
   # mormalize and strip redundand minuses
   $pat = &HTML::Entities::decode($pat,'"\'><&');
   $pat=~s/(?<!(?:-|\w))(-(?:\s+|\z))+/-/go;
   $pat=~s/\s+-$//o;
   my $l;
   $l = $logf->readline();
   $l =~ s/\\x\{\d+\}//go;
   # make line terminators uniform
   $l=~s/(.*?)(?:\r?\n|\r)/$1\n/o;
   $l=encodeHTMLEntities($l) if $l;
   $l=~s/([^\\])?\\([^\\])?/$1\\\\$2/gso;
   my @ary;
   push(@ary,$l);
   my $infinity=10000;
   my $precontext=my $postcontext=$qs{nocontext} ? 0 : 6;
   my $notmatched=0;
   my $currentpre=0;
   my $seq=0;
   my $lastoutput=$infinity;
   my $cur=$ary[0];
   my $i=0;
   my @words=map/^\d+\_(.*)/o, sort values %{{map{lc $_ => sprintf("%02d",$i++).'_'.$_} split(/\s+/o,$pat)}};
   $pat=join(' ', @words);
   my @highlights=('<span%%20%%style="color:black;%%20%%background-color:#ffff66">',
                   '<span%%20%%style="color:black;%%20%%background-color:#A0FFFF">',
                   '<span%%20%%style="color:black;%%20%%background-color:#99ff99">',
                   '<span%%20%%style="color:black;%%20%%background-color:#ff9999">',
                   '<span%%20%%style="color:black;%%20%%background-color:#ff66ff">',
                   '<span%%20%%style="color:white;%%20%%background-color:#880000">',
                   '<span%%20%%style="color:white;%%20%%background-color:#00aa00">',
                   '<span%%20%%style="color:white;%%20%%background-color:#886800">',
                   '<span%%20%%style="color:white;%%20%%background-color:#004699">',
                   '<span%%20%%style="color:white;%%20%%background-color:#990099">');
   my $findExpr=join(' && ',((map{'$cur=~/'.quotemeta($_).'/io'} map/^([^-].*)/o, split(/\s+/o,$pat)),
                             (map{'$cur!~/'.quotemeta($_).'/io'} map/^-(.*)/o, split(/\s+/o,$pat))));
   my %replace = ();
   my $j=0;
   my $highlightExpr='=~s/(';
   foreach (map/^([^-].*)/o, split(/\s+/o,$pat)) {
    $replace{lc $_}=$highlights[$j % @highlights]; # pick highlight style
    $highlightExpr.=quotemeta($_).'|';
    $j++;
   }
   $highlightExpr=~s/\|$//o;
   $highlightExpr.=')/$replace{lc $1}$1<\/span>/gio';
   my $loop=<<'LOOP';
   while (time < $maxsearchtime && $cur && !($maxmatches && $matches>=$maxmatches && $notmatched>$postcontext) && !($maxlines && $lines>=$maxlines)) {
    $maxsearchtime += &MainLoop1(0) unless ++$loopcount % $loopcheck;
LOOP
    $loop.='
    if (!($maxmatches && $matches>=$maxmatches) && '.$findExpr.') {'. <<'LOOP';
     $matches++;
LOOP
     $loop.='$cur'.$highlightExpr.' unless $qs{nohighlight};'. <<'LOOP';
     if ($lastoutput<=$postcontext) {
      push(@sary,$cur);
     } else {
      push(@sary,"\r\n") if ($seq++ && ($precontext+$postcontext>0));
      for ($i=0; $i<@ary; $i++) {
       if ($i<$precontext && $currentpre==$precontext || $i<$currentpre) {
        $ary[$i]=~s/^(.*?)(\r?\n)$/<span\%\%20\%\%style="color:#999999">$1<\/span>$2/so;
       } else {
LOOP
        $loop.='$ary[$i]'.$highlightExpr.' unless $qs{nohighlight};'. <<'LOOP';
       }
       push(@sary,$ary[$i]);
      }
     }
     $lastoutput=0;
     $notmatched=0;
    } elsif ($logf->eof) {
     for (; $currentpre>=0; $currentpre--) {
      shift(@ary);
     }
     $logf->close if exists $logf->{'handle'};
     if (!($maxfiles && $files>=$maxfiles)) {
      $logf=File::ReadBackwards->new(shift(@logfiles),'(?:\r?\n|\r)',1);
      $files++ if $logf;
     }
     $lastoutput=$infinity;
    } elsif ($lastoutput<=$postcontext) {
     $cur=~s/^(.*?)(\r?\n)$/<span\%\%20\%\%style="color:#999999">$1<\/span>$2/so;
     push(@sary,$cur);
    }
    $lastoutput++;
    $notmatched++;
    if ($l) {
     $l = $logf->readline();
     # make line terminators uniform
     $l=~s/(.*?)(?:\r?\n|\r)/$1\n/o;
     $l =~ s/\\x\{\d+\}//go;

     my $fname;
     if ($l=~ s/(\Q$base\E\/.+?\/.+?\Q$maillogExt\E)/aAaAaAaAaAbBbBbBbBbB$maillogExt/) {
       $fname = $1;
     }

     $l=encodeHTMLEntities($l) if $l;
     $l=~s/([^\\])?\\([^\\])?/$1\\\\$2/gso;

     $l =~ s/aAaAaAaAaAbBbBbBbBbB\Q$maillogExt\E/$fname/o;
     $fname = '';

     $lines++;
    }
    push(@ary,$l);
    if ($currentpre<$precontext) {
     $currentpre++;
    } else {
     shift(@ary);
    }
    $cur=$ary[$currentpre];
   }
LOOP
   eval $loop;
   $logf->close if exists $logf->{'handle'};
  }
  my $orgmatches = $matches;
  if ($matches>0) {
   $matches = 0;
   my @rary;
   my $line = $_;
   while (@sary) {
    $_ = shift @sary;
    $maxsearchtime += &MainLoop1(0) unless ++$loopcount % $loopcheck;
    my @sp;
    my @words;
    my $pretag;
    my $posttag;
    $line = $_;
    if ($_ =~ /<\/span>/o ) {
     if (!$qs{nocontext} && $_ =~ s/^(<span\%\%20\%\%style="color:#999999">)//o) {
        $pretag = $1;
        $posttag = $1 if ($_ =~ s/(<\/span>[\r\n]*)$//o);
     }
     if ($_ =~ /<\/span>/o ) {
      my $iline = '';
      @words = split(/(<span[^>]+>|<\/span>)/o);
      my $i = 0;
      while (@words) {
        $sp[$i][0] = shift @words;
        $sp[$i][1] = shift @words;
        $sp[$i][2] = shift @words;
        $sp[$i][3] = shift @words;
        $iline .=  $sp[$i][0] . $sp[$i][2];
        $i++;
      }
      if ($iline =~ /\Q$base\E\/(?:$spamlog|$discarded|$notspamlog|$incomingOkMail|$viruslog|$correctedspam|$correctednotspam|$resendmail|$rspamlog|$rnotspamlog|$rcorrectedspam|$rcorrectednotspam)\/\S[^\r\n\t]*?(?:\Q$maillogExt\E|\Q$reportExt\E)/) {
          $line = $iline ;
      } else {
         @sp = ();
      }
     }
    }
    $_ = $line;
    if (/^(<[^<>]+>)*(.*?)(\Q$base\E\/(($spamlog|$discarded|$notspamlog|$incomingOkMail|$viruslog|$correctedspam|$correctednotspam|$resendmail|$rspamlog|$rnotspamlog|$rcorrectedspam|$rcorrectednotspam)\/\S[^\r\n\t]*?(?:\Q$maillogExt\E|\Q$reportExt\E)))(.*)$/)
    {
        my $sp = $1;
        my $text = $2;
        my $file = my $hfile = $3;
        my $hlfile = $4;
        my $dname = $5;
        my $text2 = $6;
        my $span = ($dname =~ /^(?:$spamlog|$discarded|$viruslog|$correctedspam|$rspamlog|$rcorrectedspam)$/) ? 'negative' : 'positive';
        $span = 'spampassed' if /\[spam passed\]/gio;

        if (@sp) {
            my $i = 0;
            my $j = scalar @sp;
            my $fpos = 0;
            my $tpos = 0;
            my $t2pos = 0;
            while ($j > $i) {
              my ($s0,$s1,$s2,$s3) = ($sp[$i][0],$sp[$i][1],$sp[$i][2],$sp[$i][3]);
              if ($s1) {
                  pos($text) = $tpos;
                  $text =~ s/\Q$s0$s2\E/$s0$s1$s2$s3/;
                  $tpos = pos($text);
                  if ($tpos) {
                      $tpos += length($s1 . $s3);
                  } else {
                      $tpos = 0;
                  }

                  pos($text2) = $t2pos;
                  $text2 =~ s/\Q$s0$s2\E/$s0$s1$s2$s3/;
                  $t2pos = pos($text2);
                  if ($t2pos) {
                      $t2pos += length($s1 . $s3);
                  } else {
                      $t2pos = 0;
                  }

                  pos($hfile) = $fpos;
                  $hfile =~ s/\Q$s0$s2\E/$s0$s1$s2$s3/;
                  $fpos = pos($hfile);
                  if ($fpos) {
                      $fpos += length($s1 . $s3);
                  } else {
                      $fpos = 0;
                  }
              }
              $i++;
            }
        }
        $hfile =~ s/\Q$base\E\///o;

        if (&existFile($file)) {
          $hfile = "<span\%\%20\%\%style=\"white-space:nowrap;\"\%\%20\%\%onclick=\"popFileEditor('" . &normHTML($hlfile) . "','m');\"\%\%20\%\%class=\"" . $span . "\"\%\%20\%\%onmouseover=\"fileBG=this.style.backgroundColor;\%\%20\%\%this.style.backgroundColor='#BBBBFF';\"\%\%20\%\%onmouseout=\"this.style.backgroundColor=fileBG;\"><b>" . $hfile . "<\/b><\/span>";
        } else {
          $hfile =~ s/([^ ]+)( +)?/<span style="white-space:nowrap;">$1<\/span>$2/go;
        }
        $text = $sp . $text .$hfile . $text2;
        my $out = '<div%%20%%id="ll' . $matches .'"%%20%%class="assplogline'. ($currWrap + ($matches % 2 && $colorLines)) .'">' . $text . "\n</div>";
        $out =~ s/\%\%20\%\%/ /go;
        push(@rary,$pretag . $out . $posttag);
        $matches++;
        next;
    } elsif (! $filesonly) {
        s/\%\%20\%\%/ /go;
        $_ = niceLink($_);
        my @links;
        my @addr;
        my @ips;
        while ($_ =~ s/(\<a href.*?<\/a\>)/XXXIIIXXX/o) {
            my $link = $1;
            $link =~ s/WIDTH=[^\d]*(\d+\%)[^ ]*/WIDTH=$1/io;
            push @links,$link;
        }
        if (&canUserDo($WebIP{$ActWebSess}->{user},'action','addraction')) {
            while ($_ =~ s/((?<!Message-ID found: ))($EmailAdrRe\@$EmailDomainRe)/$1XXXAIIIDXXX/o) {
                push @addr ,
                   "<span style=\"white-space:nowrap;\" onclick=\"popAddressAction('"
                   . &normHTML($2)
                   . "');\" class=\"menuLevel2\" onmouseover=\"fileBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=fileBG;\"><b>"
                   . $2
                   . "<\/b><\/span>";
            }
        }
        if (&canUserDo($WebIP{$ActWebSess}->{user},'action','ipaction')) {
            while ($_ =~ s/($IPRe)([^:\d\/])/XXXiIIIpXXX$2/o) {
                my  $ip = $1;
                if (   $ip !~ /$IPprivate/o
                    && $ip ne $localhostip
                    && $ip !~ /$LHNRE/)
                {
                    push @ips,
                       "<span style=\"white-space:nowrap;\" onclick=\"popIPAction('"
                       . &normHTML($ip)
                       . "');\" class=\"menuLevel2\" onmouseover=\"fileBG=this.style.backgroundColor; this.style.backgroundColor='#BBBBFF';\" onmouseout=\"this.style.backgroundColor=fileBG;\"><b>"
                       . $ip
                       . "<\/b><\/span>";
                } else {
                    push @ips, $ip;
                }
            }
        }
        if (@links) {
            s/XXXIIIXXX/shift(@links)/geo;
        }
        if (@addr) {
            s/XXXAIIIDXXX/shift(@addr)/geo;
        }
        if (@ips) {
            s/XXXiIIIpXXX/shift(@ips)/geo;
        }
    }
    if ($filesonly) {
        next;
    }
    my $out =  '<div id="ll' . $matches .'" class="assplogline'. ($currWrap + ($matches % 2 && $colorLines)) .'">' . $_ . "\n</div>";
    push(@rary, $pretag . $out . $posttag);
    $matches++;
   }
   $s = join('', reverse @rary);
   $s =~ s/"/\\"/go;
   $s =~ s/\n+<\/div>/<\/div>XXXIIIXXX/go;
   $s =~ s/\r|\n//go;
   $s =~ s/XXXIIIXXX$//o;
   my $ftext = $filesonly ? ' with ' . needEs($matches,' line','s') . ' that contains filesnames' : '';
   $res='found '. needEs($orgmatches,' matching line','s') . $ftext . ', searched in '. needEs($files,' log file','s') .' ('. needEs($lines,' line','s'). ')';
  } else {
   $res='no results found, searched in '. needEs($files,' log file','s') .' ('. needEs($lines,' line','s'). ')';
  }
 } else {
  $s='<p class="warning">Please install required module <a href="http://search.cpan.org/~uri/File-ReadBackwards-1.03/" rel="external">File::ReadBackwards</a>.</p>';
 }
 $MaillogTailBytes = $savTailByte;
 my $size = $qs{size} ? $qs{size} : 10000;
 my $files = $qs{files} || 'lines';
 my $limit = $qs{limit} || 10;
 $pat = ($resetpat) ? '' : &HTML::Entities::encode($orgpat,'"\'><&');
 my $h1 = $WebIP{$ActWebSess}->{lng}->{'msg500050'} || $lngmsg{'msg500050'};
 my $h2 = $WebIP{$ActWebSess}->{lng}->{'msg500051'} || $lngmsg{'msg500051'};
 my $h4 = $WebIP{$ActWebSess}->{lng}->{'msg500052'} || $lngmsg{'msg500052'};
 my $h5 = $WebIP{$ActWebSess}->{lng}->{'msg500053'} || $lngmsg{'msg500053'};
 $h1 =~ s/\r|\n//go;
 $h2 =~ s/\r|\n//go;
 $h4 =~ s/\r|\n//go;
 $h5 =~ s/\r|\n//go;

 my $dir = $base;
 $dir .= "/$1" if $logfile =~ /^([^\/]+)\//o;
 my ($lf) = $logfile =~/([^\/]+)$/o;
 my $h3 = '<center><table BORDER CELLSPACING=2 CELLPADDING=4><tr><th></th><th>filename</th><th>size</th><th></th><th>filename</th><th>size</th></tr>';
 $h3 .= '<tr><td>01</td><td>' . $lf . '</td><td>' . formatDataSize( -s "$dir/$lf", 1 ) . '</td></tr>';
 my @filelist = $unicodeDH->($dir);
 my $i = 0;
 foreach my $file (reverse sort @filelist) {
     next if $file !~ /\.$lf$/;
     $h3 .= '<tr>' unless $i % 2;
     $h3 .= '<td>' . sprintf("%02d",($i + 2)) . '</td><td>' . $file . '</td><td>' . formatDataSize( -s "$dir/$file", 1 ) . '</td>';
     $h3 .= '</tr>' if $i % 2;
     $i++;
 }
 $h3 .= '</tr>' if $h3 !~ /tr\>$/;
 $h3 .= '</table></center>';
 $maxsearchtime = int($maxsearchtime + 0.5 - $stime);
 $stime = time - $stime;
 if ($maxsearchtime > $stime && $maxsearchtime > $maxsearchsec) {
     $maxsearchtime = " (calculated maximum of $stime seconds was reached)";
 } else {
     $maxsearchtime = '';
 }
 $res .= ', ' if ($res &&  $qs{autorefresh} ne 'Auto');
 $res .= "searchtime $stime seconds$maxsearchtime" if ($qs{autorefresh} ne 'Auto');
 my $headline = ($qs{autorefresh} eq 'Auto') ? '' : '<h2>SPAMBOX Maillog Tail</h2>' ;

<<EOT;
$headerHTTP
$headerDTDTransitional
$$CMheaders
<style type="text/css">
.spampassed { color: #FFA500; }
</style>
<div id="cfgdiv" $content>
$headline
<a name="MlTop" style="font-weight: normal;"></a>
<div class="log" ><pre><a id="dummy" name="dummy" style="font-weight: normal;">$m</a></pre></div>
<script type="text/javascript">
var fileBG;
var MlEndPos;

var intend = document.getElementById('dummy').offsetWidth;
document.getElementById('dummy').style.display='none';

document.write("<style id=\\"aloli0\\" type=\\"text/css\\">\\n.assplogline0\\n {\\nwhite-space:nowrap;\\n padding-left:" + intend + "px;\\n text-indent:-" + intend + "px;\\n background-color:#FFFFFF;\\n}\\n</style>\\n");
document.write("<style id=\\"aloli1\\" type=\\"text/css\\">\\n.assplogline1\\n {\\nwhite-space:nowrap;\\n padding-left:" + intend + "px;\\n text-indent:-" + intend + "px;\\n background-color:#F0F0F0;\\n}\\n</style>\\n");
document.write("<style id=\\"aloli2\\" type=\\"text/css\\">\\n.assplogline2\\n {\\nwhite-space:normal;\\n padding-left:" + intend + "px;\\n text-indent:-" + intend + "px;\\n background-color:#FFFFFF;\\n}\\n</style>\\n");
document.write("<style id=\\"aloli3\\" type=\\"text/css\\">\\n.assplogline3\\n {\\nwhite-space:normal;\\n padding-left:" + intend + "px;\\n text-indent:-" + intend + "px;\\n background-color:#F0F0F0;\\n}\\n</style>\\n");

function changeSpan(change) {
  var iswrap = document.MTform.wrap[1].checked ? 2 : 0;
  var iscolor = document.MTform.color[1].checked ? 1 : 0;
  var dowrap = change - 2;
  for(i=0; i < $matches; i++) {
    if (change == 0 || change == 1) {
      if (change == 0) {
          document.getElementById('ll' + i).className = 'assplogline' + iswrap;
      } else {
          document.getElementById('ll' + i).className = 'assplogline' + ((i % 2) + iswrap);
      }
    } else {
      if (iscolor == 0) {
          document.getElementById('ll' + i).className = 'assplogline' + dowrap;
      } else {
          document.getElementById('ll' + i).className = 'assplogline' + ((i % 2) + dowrap);
      }
    }
  }
}
</script>
<form name="MTform" action="" method="get">
  <table class="textBox" style="width: 100%;">
    <tr>
      <td rowspan="2" align="left" $display>
        <label>wrap lines: </label>
        <input type="radio" name="wrap" ${\(! $currWrap ? ' checked="checked" ' : ' ')} value='0' onclick="javascript:changeSpan('2');" />no
        <input type="radio" name="wrap" ${\(  $currWrap ? ' checked="checked" ' : ' ')} value='2' onclick="javascript:changeSpan('4');" />yes<br />
        <label>color lines: </label>
        <input type="radio" name="color" ${\(! $colorLines ? ' checked="checked" ' : ' ')} value='0' onclick="javascript:changeSpan('0');" />no
        <input type="radio" name="color" ${\(  $colorLines ? ' checked="checked" ' : ' ')} value='1' onclick="javascript:changeSpan('1');" />yes<br />
        <label>tail bytes:</label>
        <input type="text" name="tailbyte" value='$currTailByte' size="7"/>
      </td>
      <td align="left" $display>
        <label>search for: </label>
        <a href="javascript:void(0);" onmouseover="showhint('$h5', this, event, '450px', '1');return false;"><img height=12 width=12 src="$wikiinfo" /></a>
        <input type="text" name="search" value='$pat' size="30"/>
      </td>
      <td align="left">
        <input type="submit" value="Submit/Update" $display />
        <input type="submit" name="autorefresh" value='$autoButton'/>
        <input type="hidden" name="order" value='$order'/>
      </td>
      <td rowspan="2" $display>
        <input type="checkbox" name="nocontext"${\($qs{nocontext} ? ' checked="checked" ' : ' ')}value='1' />hide&nbsp;context&nbsp;lines<br />
        <input type="checkbox" name="nohighlight"${\($qs{nohighlight} ? ' checked="checked" ' : ' ')}value='1' />no&nbsp;highlighting<br />
        <input type="checkbox" name="filesonly"${\($qs{filesonly} ? ' checked="checked" ' : ' ')}value='1' />file&nbsp;lines&nbsp;only
      </td>
    </tr>
    <tr $display>
      <td align="left">
        <label>search in:</label>
        <a href="javascript:void(0);" onmouseover="showhint('$h4', this, event, '450px', '1');return false;"><img height=12 width=12 src="$wikiinfo" /></a>
        <input type="text" name="size" value='$size' size="7" />
        <select size="1" name="files" value="$qs{files}" />
          <option value="lines">last lines</option>
          <option value="files">last log files</option>
          <option value="all">all log files</option>
          <option value="ago">this file number(s)</option>
        </select>
        <a href="javascript:void(0);" onmouseover="showhint('$h3', this, event, '450px', '1');return false;"><img height=12 width=12 src="$wikiinfo" /></a>
      </td>
      <td align="left">
        <label>show </label>
        <select size="1" name="limit" value="$qs{limit}">
          <option value="1">1</option>
          <option value="10">10</option>
          <option value="100">100</option>
          <option value="1000">1000</option>
          <option value="2000">2000</option>
        </select> Results
      </td>
    </tr>
  </table>
</form>
<script type="text/javascript">
document.MTform.files.value='$files';
document.MTform.limit.value='$limit';
function resetForm() {
  document.MTform.search.value='';
  document.MTform.nocontext.checked=false;
  document.MTform.nohighlight.checked=false;
  document.MTform.filesonly.checked=false;
  document.MTform.tailbyte.value='$MaillogTailBytes';
  document.MTform.size.value='10000';
  document.MTform.files.value='lines';
  document.MTform.limit.value='10';
  document.MTform.order.value='0';
}
</script>
<div class="log $logstyle" $display>
<a href="javascript:void(0);" onclick="document.getElementById(\'LogLines\').scrollTop=MlEndPos; return false;" >Go to End</a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="javascript:void(0);" onclick="document.getElementById(\'LogLines\').scrollTop=0;return false;">Go to Top</a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="javascript:void(0);" onmouseover="showhint('$h3', this, event, '450px', '1');return false;">show filelist</a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="javascript:void(0);" onmouseover="showhint('$h1<br /><br />$h2', this, event, ie ? document.body.offsetWidth / 2.1 + 'px' : window.innerWidth / 2.1 + 'px' , '');return false;">help</a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="javascript:void(0);" onclick="resetForm();" onmouseover="showhint('click to reset the form to system defaults', this, event, '300px', '');return false;">reset form</a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="javascript:void(0);" onclick="switchMTOrder();" onmouseover="showhint('click to switch the time order of lines', this, event, '300px', '');return false;">switch order</a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="/" onmouseover="showhint('click to return to config dialog', this, event, '300px', '');return false;">back to config</a><br />
<script type="text/javascript">
if ('$qs{autorefresh}' != 'Auto') {
//var LogWidth = objWidth('cfgdiv') + 'px';
var LogHeight = ClientSize('h') - document.getElementById('cfgdiv').offsetHeight + 'px';
}
</script>
$res
<hr>
</div>
<div id="LogLines" class="log" style="display:block;height:100%;width=100%;overflow:auto;">
<div class="log $logstyle" width=100%>
<pre id="allLogLines" style="font-size: 1.4em;">
</pre>

<script type="text/javascript">

if ('$qs{autorefresh}' != 'Auto') {
//document.getElementById('LogLines').style.width = LogWidth;
document.getElementById('LogLines').style.height = LogHeight;
}

var order = $order;
var allLines = "$s".split("XXXIIIXXX");
var allLinesF = allLines.join('');
var allLinesR = allLines.reverse().join('');
allLines = ('');
function switchMTOrder() {
  order = order ? 0 : 1 ;
  document.MTform.order.value=order;
  var logdiv = document.getElementById('allLogLines');
  logdiv.innerHTML = '';
  if (order == 1) {
      logdiv.innerHTML = allLinesR;
  } else {
      logdiv.innerHTML = allLinesF;
  }
}
order = order ? 0 : 1 ;
switchMTOrder();
if ('$qs{autorefresh}' != 'Auto') {
MlEndPos = document.getElementById('allLogLines').scrollHeight;
window.location.href = '#MlTop';
${\($MaillogTailJump && $qs{autorefresh} ne 'Auto' ? 'document.getElementById(\'LogLines\').scrollTop=MlEndPos;' : 'order = order;') }
}
</script>
</div>
<div $display >
$maillogJump
</div>
</div>
</div>
<div $display >
$footers
</div>
<form name="SPAMBOXconfig" id="SPAMBOXconfig" action="" method="post">
  <input name="theButtonLogout" type="hidden" value="" />
</form>
</body></html>
EOT
}
