#line 1 "sub main::ConfigEdit"
package main; sub ConfigEdit {
 my $fil = $qs{file};
 $qs{note} = lc $qs{note};
 my $htmlfil;
 my $note = q{};
 my ($cidr,$regexp1,$regexp2);
 my ($s1,$s2,$editButtons,$option, $ishash, $hash);
 my $noLineNum = '';

 $cidr=$regexp1=$regexp2=q{};
 
 my $hashnote = '<div class="note" id="notebox">';
 $hashnote .= $WebIP{$ActWebSess}->{lng}->{'msg500080'} || $lngmsg{'msg500080'};
 $hashnote .= '</div>';
 if ($qs{note} eq '1' or $qs{note} eq '1h'){        # edit file hash
  $note = '<div class="note" id="notebox">';
  $note .= $WebIP{$ActWebSess}->{lng}->{'msg500081'} || $lngmsg{'msg500081'};
  $note .= '</div>';
 }
 elsif($qs{note} eq '2'){
  $note = '<div class="note" id="notebox">';
  $note .= $WebIP{$ActWebSess}->{lng}->{'msg500082'} || $lngmsg{'msg500082'};
  $note .= '</div>';
 }
 elsif($qs{note} eq '3'){
  $note = '<div class="note" id="notebox">';
  $note .= $WebIP{$ActWebSess}->{lng}->{'msg500083'} || $lngmsg{'msg500083'};
  $note .= '</div>';
 }
 elsif($qs{note} eq '4'){
  $note = '<div class="note" id="notebox">';
  $note .= $WebIP{$ActWebSess}->{lng}->{'msg500084'} || $lngmsg{'msg500084'};
  $note .= '</div>';
 }
   elsif($qs{note} eq '5'){
  $note = '<div class="note" id="notebox"></div>';
 }
  elsif($qs{note} eq '6'){
  $note = '<div class="note" id="notebox">';
  $note .= $WebIP{$ActWebSess}->{lng}->{'msg500086'} || $lngmsg{'msg500086'};
  $note .= '</div\>';
 }
 elsif($qs{note} eq '8' or $qs{note} eq '9'){       # show  file hash
  $note = '<div class="note" id="notebox"></div>';
 }
 elsif ($qs{note} eq 'm'){                          # mail file
        $fil="$base/$fil" if $fil!~/^\Q$base\E/io;
        $option  = "<option value=\"0\">select action</option>";
        $option .= "<option value=\"1\">copy file to resendmail</option>" if($CanUseEMS && $resendmail && $fil !~/\/$resendmail\//);
        $option .= "<option value=\"2\">save file</option>";
        $option .= "<option value=\"3\">copy file to notspamlog</option>" if ($fil !~/\/$notspamlog\//);
        $option .= "<option value=\"4\">copy file to spamlog</option>" if ($fil !~/\/$spamlog\//);
        $option .= "<option value=\"5\">copy file to incomingOkMail</option>" if ($fil !~/\/$incomingOkMail\//);
        $option .= "<option value=\"6\">copy file to viruslog</option>" if ($fil !~/\/$viruslog\//);
        $option .= "<option value=\"7\">copy file to correctedspam</option>" if ($fil !~/\/$correctedspam\//);
        $option .= "<option value=\"8\">copy file to correctednotspam</option>" if ($fil !~/\/$correctednotspam\//);
        $option .= "<option value=\"9\">copy file to rebuild_error</option>" if ($fil !~/\/rebuild_error\//);

        $note = '<div class="note" id="notebox">';
        $note .= $WebIP{$ActWebSess}->{lng}->{'msg500090'} || $lngmsg{'msg500090'};
        $note .= $WebIP{$ActWebSess}->{lng}->{'msg500091'} || $lngmsg{'msg500091'} if !($CanUseEMS && $resendmail && $fil !~/\/$resendmail\//);
 }

#$regexp1 = $WebIP{$ActWebSess}->{lng}->{'msg500011'} || $lngmsg{'msg500011'} if !$CanMatchCIDR;
#$regexp2 = $WebIP{$ActWebSess}->{lng}->{'msg500012'} || $lngmsg{'msg500012'} if !$CanMatchCIDR;
$regexp1 = $WebIP{$ActWebSess}->{lng}->{'msg500013'} || $lngmsg{'msg500013'};
$regexp2 = $WebIP{$ActWebSess}->{lng}->{'msg500014'} || $lngmsg{'msg500014'};

$cidr = $WebIP{$ActWebSess}->{lng}->{'msg500015'} || $lngmsg{'msg500015'} if !$CanUseCIDRlite;
$cidr = $WebIP{$ActWebSess}->{lng}->{'msg500016'} || $lngmsg{'msg500016'} if $CanUseCIDRlite;
 if ($qs{note} eq '7'){
  $note = "<div class='note' id='notebox'>";
  $note .= $WebIP{$ActWebSess}->{lng}->{'msg500092'} || $lngmsg{'msg500092'};
  $note .= "$regexp1 $cidr $regexp2</div>";
 }
 $s2 = '';
 my $certsRe = quotemeta($SSLCertFile).'|'.quotemeta($SSLKeyFile).'|'.quotemeta($SSLCaFile);
 my $sfile = "$fil";
 $sfile="$base/$sfile" if $sfile!~/^\Q$base\E/io;
 if ($fil =~ /\.\./o){
  $s2.='<div class="text"><span class="negative">File path includes \'..\' -- access denied</span></div>';
  mlog(0,"file path not allowed while editing file '$fil'");
 } elsif ($WebIP{$ActWebSess}->{user} ne 'root' && ($sfile=~/^(?:$certsRe)$/i || $sfile =~ /notes[\\\/]configdefaults\.txt/io)) {
  mlog(0,"error: user $WebIP{$ActWebSess}->{user} has tried to show/edit security file '$sfile'");
  $s2.='<div class="text"><span class="negative">File $sfile has secured access rules -- access denied</span></div>';
 } else {
  #$fil="$base/$fil" if $fil!~/^(([a-z]:)?[\/\\]|\Q$base\E)/;
  if ($fil =~ /^DB-(.+)/o) {
      $ishash = $1;
      $hash = getHashName($ishash,'');
      $htmlfil = $fil;
      $note = $hashnote.$note;
      $note =~ s/\<\/div\>\<div class\=\"note\" id\=\"notebox\"\>/<br \/><br \/>/o;
  } else {
      $hash = getHashName('', $fil);
      if ($hash) {
          $ishash = $hash;
          SaveHash($hash);
          $htmlfil = $fil;
          $note = $hashnote.$note;
          $note =~ s/\<\/div\>\<div class\=\"note\" id\=\"notebox\"\>/<br \/><br \/>/o;
      } else {
          $fil="$base/$fil" if $fil!~/^\Q$base\E/io;
          $htmlfil = $fil;
          $ishash = 0;
      }
  }
  if ($qs{B1}=~/delete/io) {
    if ($ishash) {
       if ($hash) {
           %$hash = ();
           $s2='<span class="positive">list ' .$ishash. ' cleaned successfully</span>';
       } else {
           $s2='<span class="negative">unable to clean list ' .$ishash.' - no such list</span>';
       }
    } else {
       if ($unlink->($fil)) {
           $s2='<span class="positive">File '.$fil.' deleted successfully</span>';
       } else {
           $s2='<span class="negative">unable to delete File ' .$fil. ' - $!</span>';
           mlog(0,"error: unable to delete file $fil - $!");
       }
    }
  } else {
   if (defined($qs{contents})) {
    $s1=$qs{contents};
    $s1= decodeHTMLEntities($s1);
    $s1 =~ s/\n$//o; # prevents SPAMBOX from appending a newline to the file each time it is saved.
    $s1 =~ s/\r$//o;
    $s1 =~ s/\s+$//o;
   # make line terminators uniform
    if ($qs{note} ne 'm') {
      $s1 =~ s/\r?\n/\n/go;
      if ($ishash) {
        if ($hash) {
            $s1 =~ s/\[(\+?\d{4}\-\d{2}\-\d{2}\,\d{2}\:\d{2}\:\d{2})\]/&timeval($1)/geo
                if $hash ne 'Stats';
            if ($qs{B1}=~/Save to Importfile/io) {
                my $filename = getHashBDBName($hash);
                $filename = "/$filename" if $filename !~ /\//o;
                ($filename) = $filename =~ /^.*\/([^\/]+)$/o;
                $filename = "$base/$importDBDir/$filename.rpl";
                unlink "$base/$importDBDir/$filename.rpl.OK";
                $s1 =~ s/[\s\n]*$//o;
                $s1 =~ s/^[\s\n]*//o;
                $s1 =~ s/\n{2,}/\n/go;
                $s1 =~ s/\|::\|/\x02/go;
                $s1 = "\n" . $s1;
                if (open(my $CE,">",$filename)) {
                    binmode $CE;
                    print $CE $s1;
                    close $CE;
                    $s2='<span class="positive">Importfile '.$filename.' saved successfully</span>';
                    if (! $RunTaskNow{ImportMysqlDB} && ! $RunTaskNow{ExportMysqlDB}) {
                        $RunTaskNow{ImportMysqlDB} = 10000;
                        $s2 .='<br /><span class="positive">DB-Import was queued to run</span>';
                    } else {
                        $s2 .='<br /><span class="negative">DB-Import or DB-Export is still running</span>';
                    }
                } else {
                    $s2='<span class="negative">unable to save Importfile '.$filename.' - $@</span>';
                }
            } else {
                $s1 =~ s/[\s\n]*$//o;
                $s1 =~ s/^[\s\n]*//o;
                $s1 =~ s/\n{2,}/\n/go;
                %$hash = split(/\|::\||\n/o,$s1);
                delete $$hash{''};
                $s2='<span class="positive">list saved successfully</span>';
            }
        } else {
            $s2='<span class="negative">unable to save list ' .$ishash. ' - no such list</span>';
        }
      } else {
        if (open(my $CE,">",$fil)) {
            binmode $CE;
#encrypt if to do
            if (exists $CryptFile{$fil}) {
                my $enc = SPAMBOX::CRYPT->new($webAdminPassword,0);
                $s1 = $enc->ENCRYPT($s1)
            }
            print $CE $s1;
            close $CE;
            $s2='<span class="positive">File saved successfully</span>';
            if ($fil =~ /language\//o) {
                $WebIP{$ActWebSess}->{changedLang} = 1;
            } else {
                $ConfigChanged = 1;
                &tellThreadsReReadConfig();   # reread the config to get regex mistakes in edit browser
            }
        } else {
            $s2='<span class="negative">unable to save File $fil - $!</span>';
            mlog(0,"error: unable to save file $fil - $!");
        }
      }
    } else {      # to take actions on a mailfile
         $s1 =~ s/([^\r])\n/$1\r\n/go;
         $s1 .= "\r\n";
         my $action = $qs{fileaction};
         if ($action eq '1') {    # resend
             $s1 = "\r\n" . $s1;
             my $rfil = $fil;
             $rfil =~ s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$resendmail$2/i;
             my ($to) = $s1 =~ /\nX-Assp-Intended-For:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio;
             ($to) = $s1 =~ /\nto:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio unless $to;
             my ($from) = $s1 =~ /\nX-Assp-Envelope-From:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio;
             ($from) = $s1 =~ /\nfrom:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio unless $from;
             $s1 =~ s/^\r\n//o;
             $s2='';
             if (! $to ) {
                 $s2 .= '<br />' if $s2;
                 $s2 .= '<span class="negative">!!! no addresses found in X-Assp-Intended-For: or TO: header line - please check !!!</span>';
             }
             if (! $from ) {
                 $s2 .= '<br />' if $s2;
                 $s2 .= '<span class="negative">!!! no addresses found in X-Assp-Envelope-From: or FROM: header line - please check !!!</span>';
             }
             if ((! $nolocalDomains && ! (localmail($to) or localmail($from)))) {
                 $s2 .= '<br />' if $s2;
                 $s2 .= '<span class="negative">!!! no local addresses found in X-Assp-Intended-For: or TO: header line - please check !!!</span>'
                     unless localmail($to);
                 $s2 .= '<br />' if $s2 =~ /span>$/o;
                 $s2 .= '<span class="negative">!!! no local addresses found in X-Assp-Envelope-From: or FROM: header line - please check !!!</span>'
                     unless localmail($from);
             }
             if (! $s2) {
                 if ($open->(my $CE,'>',$rfil)) {
                     $CE->binmode;
                     $CE->print($s1);
                     $CE->close;
                     $s2 .= '<span class="positive">File copied to resendmail folder</span>';
                     mlog(0,"info: request to create file: $rfil");
                     $nextResendMail = $nextResendMail < time + 3 ? $nextResendMail: time + 3;
                 } else {
                     $s2 .= '<span class="negative">unable to create file in resendmail folder - $!</span>';
                     mlog(0,"error: unable to create file in resendmail folder - $!");
                 }
             }
         } elsif ($action eq '2') {    # save
             if ($open->(my $CE,'>',$fil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 my $rs = quotemeta($correctedspam);
                 my $rh = quotemeta($correctednotspam);
                 if ($eF->( $fil ) && $fil =~ /(?<s>$rs)|(?<h>$rh)/o) {
                     $newReported{$fil} = $+{s} ? 'spam' : 'ham';
                 }
                 $s2='<span class="positive">File saved successfully</span>';
             } else {
                 $s2='<span class="negative">unable to save file - $!</span>';
                 mlog(0,"error: unable to save file - $!");
             }
         } elsif ($action eq '3') {    # copy to notspam
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$notspamlog$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to notspamlog folder</span>';
                 mlog(0,"info: request to create file: $rfil");
             } else {
                 $s2='<span class="negative">unable to create file in notspamlog folder - $!</span>';
                 mlog(0,"error: unable to create file in notspamlog folder - $!");
             }
         } elsif ($action eq '4') {    # copy to spam
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$spamlog$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to spamlog folder</span>';
                 mlog(0,"info: request to create file: $rfil");
             } else {
                 $s2='<span class="negative">unable to create file in spamlog folder - $!</span>';
                 mlog(0,"error: unable to create file in spamlog folder - $!");
             }
         } elsif ($action eq '5') {    # incomingOkMail
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$incomingOkMail$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to incomingOkMail folder</span>';
                 mlog(0,"info: request to create file: $rfil");
             } else {
                 $s2='<span class="negative">unable to create file in incomingOkMail folder - $!</span>';
                 mlog(0,"error: unable to create file in incomingOkMail folder - $!");
             }
         } elsif ($action eq '6') {    # viruslog
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$viruslog$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to viruslog folder</span>';
                 mlog(0,"info: request to create file: $rfil");
             } else {
                 $s2='<span class="negative">unable to create file in viruslog folder - $!</span>';
                 mlog(0,"error: unable to create file in viruslog folder - $!");
             }
         } elsif ($action eq '7') {    # correctedspam
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$correctedspam$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to correctedspam folder</span>';
                 mlog(0,"info: request to create file: $rfil");

                 my ($to) = $s1 =~ /\nX-Assp-Intended-For:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio;
                 ($to) = $s1 =~ /\nto:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio unless $to;
                 my ($from) = $s1 =~ /\nX-Assp-Envelope-From:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio;
                 ($from) = $s1 =~ /\nfrom:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio unless $from;
                 if (   ($EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP == 1 || matchSL( $to, 'EmailErrorsModifyPersBlack' ))
                     && $to
                     && &localmail($to)
                     && $from && lc $from ne 'spambox <>'
                     && ! &localmail($from)
                    )
                 {
                     if (matchSL( $to, 'EmailErrorsModifyPersBlack' , 1)) {
                         $s2 .= modListOnEdit('EmailPersBlackAdd',$to,\$s1,undef);
                         mlog( 0, "info: possibly personal black entries added on File copied to correctedspam folder" )
                           if $MaintenanceLog;
                     }
                     if ($EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP == 1) {
                         $s2 .= modListOnEdit('EmailSpam',$to,\$s1,undef);
                         mlog( 0, "info: possibly noprocessing and/or whitelist entries removed on File copied to correctedspam folder" )
                           if $MaintenanceLog;
                     }
                 }
                 $eF->( $rfil ) && ($newReported{$rfil} = 'spam');
             } else {
                 $s2 = '<span class="negative">unable to create file in correctedspam folder - $!</span>';
                 mlog(0,"error: unable to create file in correctedspam folder - $!");
             }
         } elsif ($action eq '8') {    # correctednotspam
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/).+(\/.+\Q$maillogExt\E)$/$1$correctednotspam$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to correctednotspam folder</span>';
                 mlog(0,"info: request to create file: $rfil");

                 my ($to) = $s1 =~ /\nX-Assp-Intended-For:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio;
                 ($to) = $s1 =~ /\nto:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio unless $to;
                 my ($from) = $s1 =~ /\nX-Assp-Envelope-From:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio;
                 ($from) = $s1 =~ /\nfrom:[^\<]*?<?($EmailAdrRe\@$EmailDomainRe)>?/sio unless $from;
                 if (   ($EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP == 1 || matchSL( $to, 'EmailErrorsModifyPersBlack' ))
                     && $to
                     && &localmail($to)
                     && $from
                     && lc $from ne 'spambox <>'
                     && ! &localmail($from)
                    )
                 {
                     if (matchSL( $to, 'EmailErrorsModifyPersBlack', 1 )) {
                         $s2 .= modListOnEdit('EmailPersBlackRemove',$to,\$s1,undef);
                         mlog( 0, "info: possibly personal black entries removed on File copied to correctednotspam folder" )
                           if $MaintenanceLog;
                     }
                     if ($EmailErrorsModifyWhite == 1 || $EmailErrorsModifyNoP == 1) {
                         $s2 .= modListOnEdit('EmailHam',$to,\$s1,undef);
                         mlog( 0, "info: possible noprocessing and/or whitelist entries added on File copied to correctednotspam folder" )
                           if $MaintenanceLog;
                     }
                 }
                 $eF->( $rfil ) && ($newReported{$rfil} = 'ham');
             } else {
                 $s2='<span class="negative">unable to create file in correctednotspam folder - $!</span>';
                 mlog(0,"error: unable to create file in correctednotspam folder - $!");
             }
         } elsif ($action eq '9') {    # copy to rebuild_error
             my $rfil = $fil;
             $rfil =~s/^(\Q$base\E\/)(.+\/.+\Q$maillogExt\E)$/$1rebuild_error\/$2/i;
             if ($open->(my $CE,'>',$rfil)) {
                 $CE->binmode;
                 $CE->print($s1);
                 $CE->close;
                 $s2='<span class="positive">File copied to rebuild_error folder</span>';
                 mlog(0,"info: request to create file: $rfil");
             } else {
                 $s2='<span class="negative">unable to create file in rebuild_error folder - $!</span>';
                 mlog(0,"error: unable to create file in rebuild_error folder - $!");
             }
         }
         $qs{fileaction} = '0';
    }
   }
  }
  if ($ishash) {
    if ($hash) {
      if($qs{B1}!~/Save to Importfile/io) {
        my @S1;
        my $i = 0;
        if ($hash =~ /^T10Stat(.)$/o) {
            my @th = &T10StatGet($1,0);
            while (@th) {
                push @S1 , encodeHTMLEntities((shift @th) .'|::|'. (shift @th));
            }
        } else {
            while ( my ($k,$v) = each %$hash) {
                next unless $k;
                $v =~ s/(\d{10,11})/'[' . &timestring($1,'','YYYY-MM-DD,hh:mm:ss') . ']'/geo
                    if (   $qs{note} ne 'm'
                        && $hash ne 'Stats');
                push @S1, encodeHTMLEntities("$k\|::\|$v");
                if ($i++ == 1000) {
                    &ThreadMonitorMainLoop("read HASH $hash - $i records - for GUI-Edit");
                    $i = 0;
                }
            }
        }
        my $cnt = scalar @S1;
        $s1 = join("\n",@S1);
        if ($cnt > 10000) {
            $note =~ s/<\/div>//o;
            $note .= '<span class="negative"><br />';
            $note .= $WebIP{$ActWebSess}->{lng}->{'msg500093'} || $lngmsg{'msg500093'};
            $note .= $cnt.' ';
            $note .= $WebIP{$ActWebSess}->{lng}->{'msg500094'} || $lngmsg{'msg500094'};
            $note .= '</span></div>';
        }
      } else {
            $note = '<div class="note" id="notebox"><span class="negative">';
            $note .= $WebIP{$ActWebSess}->{lng}->{'msg500095'} || $lngmsg{'msg500095'};
            $note .= '</span></div>';
      }
    }
  } else {
    if($open->(my $CE,'<',$fil)) {
     $CE->read($s1,[$stat->($fil)]->[7]);
#dencrypt if to do
     if (exists $CryptFile{$fil} && $s1 =~ /^(?:[a-zA-Z0-9]{2})+$/o) {
         my $enc = SPAMBOX::CRYPT->new($webAdminPassword,0);
         $s1 = $enc->DECRYPT($s1);
     }
     $CE->close;
     if ($qs{note} eq '9') {
         my $body = cleanMIMEBody2UTF8(\$s1);
         $body ||= 'decoding error';
         $s1 = cleanMIMEHeader2UTF8(\$s1,0) . $body;
         $s1 = encodeHTMLEntities($s1);
         $s1 =~ s/(?:\r?\n|\r)/\n/go;
     } else {
         $s1 =~ s/(?:\r?\n|\r)/\n/go;
         $s1= encodeHTMLEntities($s1);
     }
    } else {
     $s2='<span class="negative">'.ucfirst($!).'</span>';
    }
  }

  my $slo;
  $slo = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button"  name="showlogout" value="  logout " onclick="window.location.href=\'./logout\';return false;"/></span>' if exists $qs{showlogout};

  if ($eF->( $fil ) or $fil =~ /^DB-/o) {
      if($qs{note} eq '8' or $qs{note} eq '9') {
          $editButtons='<div><input type="button" value="Close" onclick="javascript:window.close();"/></div>';
          $noLineNum = 'return false;';
      } elsif ($qs{note} eq 'm') {
          $noLineNum = 'return false;';
          if ($s1 !~ /\n\.\n+$/o) {
              $note .= '<br /><font color=blue>';
              $note .= $WebIP{$ActWebSess}->{lng}->{'msg500096'} || $lngmsg{'msg500096'};
              $note .= '</font>';
          }
          $note .= '</div>';

          $editButtons="
 <div style=\"align: left\">
  <div class=\"shadow\">
   <div class=\"option\">
    <div class=\"optionValue\">
     <select size=\"1\" name=\"fileaction\">" .
      $option . "
     </select>
    </div>
   </div>
  </div>
 </div>
 &nbsp;&nbsp;";

          $editButtons .='<div><input type="submit" name="B1" value="Do It!" />&nbsp;&nbsp;<input type="submit" name="B1" value="Delete file" onclick="return confirmDelete(\''.$fil.'\');"/>';
          my $nf = normHTML($fil);

          $editButtons .='&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button" value="view decoded MIME" onclick="return popFileEditor(\''. $nf .'\',9);"/>&nbsp;&nbsp;<input type="button" value="analyze" onclick="return window.open(\'analyze?file='. $nf .'\',\'SPAMBOX Analyze\',\'\');"/> &nbsp;&nbsp;<input type="button" value="Close" onclick="javascript:window.close();"/>'.$slo.'</div>';
      } else {
          my $disabled = ($qs{B1}=~/Save to Importfile/io) ? 'disabled="disabled"' : '';
          my $fn = $hash ? 'list' : 'file';
          my $savetofile = ($hash && $importDBDir && $qs{note} ne '1h') ? '&nbsp;<input type="submit" name="B1" value="Save to Importfile" '.$disabled.' />' : '';
          $editButtons='<div><input type="submit" name="B1" value="Save changes" '.$disabled.' />&nbsp;<input type="submit" name="B1" '.$disabled.' value="Delete '. $fn . '" onclick="return confirmDelete(\''.$fil.'\');"/>'.$savetofile .'
              &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button" value="Close" onclick="javascript:window.close();"/>'.$slo.'</div>';
      }
  } else {
   $noLineNum = 'return false;';
   my $fn = $hash ? 'list' : 'file';
   $s2='<div class="text"><span class="positive">'.$fn.' deleted</span></div>' if $qs{B1}=~/delete/io;
   $editButtons='<div><input type="submit" name="B1" value="Save changes" />&nbsp;<input type="submit" name="B1" value="Delete '.$fn.'" disabled="disabled" />
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="button" value="Close" onclick="javascript:window.close();"/>'.$slo.'</div>';

  }		
 }

 my $s3;
 if ($qs{note} eq '1') {
     my $currStat = &StatusSPAMBOX();
     if ($currStat =~ /not healthy/io) {
       $s3 = '<a href="./statusspambox" target="blank" title="SPAMBOX '.$version.$modversion.($codename?" ( code name $codename )":'').' is running not healthy! Click to show the current detail thread status."><b><font color=\'red\'>&bull;';
       if (scalar keys %RegexError) {
           $s3 .= '&nbsp;-&nbsp; regex error in:&nbsp;';
           foreach(keys %RegexError) {
              $s3 .= $_ . ',&nbsp';
           }
           $s3 =~ s/,\&nbsp$/<br \/>/o;
       }
       $s3 .= '</font></b></a>';
     }
 }

 return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage SPAMBOX File Editor ($myName $htmlfil)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
    <script type="text/javascript">
//<![CDATA[
	// Javascript code and layout adapted from TinyMCE
	// http://tinymce.moxiecode.com/
    <!--
    var wHeight=0, wWidth=0, owHeight=0, owWidth=0;
	
    function resizeInputs() {
	    var contents = document.getElementById('contents');
	    var notebox = document.getElementById('notebox');
		//alert(el2.offsetHeight);

	    if (!isIE()) {
	    	 //alert(navigator.userAgent);
	         wHeight = self.innerHeight - (notebox.offsetHeight+150);
	         wWidth = self.innerWidth - 50;
	    } else {
			 //alert(navigator.userAgent);
	         wHeight = document.body.clientHeight - (notebox.offsetHeight+150);
	         wWidth = document.body.clientWidth - 50;
	    }

	    contents.style.height = Math.abs(wHeight) + 'px';
	    contents.style.width  = Math.abs(wWidth) + 'px';
	    container.style.height = Math.abs(wHeight - 18) + 'px';
    }
    
	function isIE () {
		var check,agent;
		check=/MSIE/i;
		agent=navigator.userAgent;
		if(check.test(agent)) {
			return true;
		} 
		else {
			return false;
		}
	}


	function confirmDelete(FileName)
	{
		var strmsg ="Are you sure you wish to delete: \\n" + FileName  + "\\n This action cannot be undone";
		var agree=confirm( strmsg );
		if (agree)
			return true;
		else
			return false;
	}

function popFileEditor(filename,note)
{
  var height = (note == 0) ? 500 : (note == \'m\') ? 580 : 550;
  newwindow=window.open(
    \'edit?file=\'+filename+\'&note=\'+note,
    \'FileEditorM\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function remember()
{
  var height =  580;
  newwindow=window.open(
    \'remember\',
    \'rememberMe\',
    \'width=720,height=\'+height+\',overflow=scroll,toolbar=yes,menubar=yes,location=no,personalbar=yes,scrollbars=yes,status=no,directories=no,resizable=yes\'
  );
  	// this puts focus on the popup window if we open a new popup without closing the old one.
  	if (window.focus) {newwindow.focus()}
  	return false;
}

function getInput() { return document.getElementById("contents").value; }
function setOutput(string) {document.getElementById("contents").value=string; }

function replaceIt() { try {
var findText = document.getElementById("find").value;
var replaceText = document.getElementById("replace").value;
setOutput(getInput().replace(eval("/"+findText+"/ig"), replaceText));
} catch(e){}}

      //-->
    //]]>
    </script>
<style type="text/css">
#container
{
	width: 40px;
	color: Gray;
	font-family: Courier New;
	font-size: 14px;
	float: left;clear: left;
	overflow: hidden;
        position: relative;
        top: 2px;
}
#divlines
{
	position: absolute;
}
</style>
</head>
<body onresize="resizeInputs();" onload="resizeInputs();" style="overflow:hidden;" onmouseover="this.focus();" ondblclick="this.select();">
    <div class="content">
      <form action="" method="post">
        <span style="float: left;">$s3<a href="javascript:void(0);" onclick="remember();return false;"><img height=12 width=12 src="$wikiinfo" alt="open the remember me window"/></a>&nbsp; Contents of $htmlfil</span><br /><hr /><br />
        <div id="message" style="float: right">$s2</div>
        <br style="clear: both;" />
        <span style="align: left">Replace: <input type="text" id="find" size="20" /> with <input type="text" id="replace" size="20" /> <input type="button" value="Replace" onclick="replaceIt();" /></span>
        <div>
          <div id="container">
            <div id="divlines">
            </div>
          </div>
          <textarea id="contents" name="contents" rows="15" style="max-width:90%;max-height:75%;width:100%;overflow:scroll;align: right;font-size: 14px; font-family: 'Courier New',Courier,monospace; " wrap="off">$s1
          </textarea>
<script type="text/javascript">
var lines = document.getElementById("divlines");
var txtArea = document.getElementById("contents");
var nLines;
window.onload = function() {
    $noLineNum
    resizeInputs();
    refreshlines();
    txtArea.onscroll = function () {
        lines.style.top = -(txtArea.scrollTop) + "px";
        return true;
    }
    txtArea.onkeyup = function () {

      var keycode;
      if (window.event) keycode = window.event.keyCode;
      else if (e) keycode = e.which;
      else return true;

      if (keycode == 13)
         {
         nLines++;
         lines.innerHTML = lines.innerHTML + nLines + "." + "<br />";
         return false;
         }
      else
         {
         return true;
         }
    }
}

function refreshlines() {
    $noLineNum
    nLines = txtArea.value.split("\\n").length;
    var innerlines = "";
    for (i=1; i<=nLines; i++) {
        innerlines = innerlines + i + "." + "<br />";
    }
    lines.innerHTML = innerlines;
    lines.style.top = -(txtArea.scrollTop) + "px";
}
</script>

          $editButtons
        </div>
      </form>
	  <br />$note
    </div>
<script type="text/javascript">
if (!isIE()) {
    resizeInputs();
    refreshlines();
}
</script>
  </body>
</html>

EOT

}
