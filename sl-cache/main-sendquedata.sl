#line 1 "sub main::sendquedata"
package main; sub sendquedata {
  my ($fh,$frfh,$m,$done)=@_;
  my $this;
  $this=$Con{$fh} if exists $Con{$fh};
  my $friend;
  $friend=$Con{$frfh} if exists $Con{$frfh};
  my $convert=0;
  my $doFixTNEF=0;
  my $keepTNEF=1;
  my %oldchrset = ();
  my $newchrset;
  my $body;
  my @newparts;
  my @TNEFparts;
  my $i=0;
  my @newwinparts;
  my $add_to_newparts=1;
  my $enc;
  my $header;
  my $headlen;
  my $pos;
  my $newpos;
  my $mimestr;
  my $newmimestr;
  my $email;
  my $dis;
  my $attrs;
  my $name;
  my $boundary;
  my $time;
  my $stderr;
  my $DKIMres;
  my $SAres;
  my $message;

  d('sendquedata');
  if (! $this) {
      mlog(0,"warning: got data from $frfh for a still closed peer - $fh");
      done($frfh) unless exists $ConDelete{$frfh}; # close the client connection - there is no more any server
      return;
  }
  if (! $friend) { # this should never - never happen
      mlog($fh,"error: got data for server $fh from unexisting peer $frfh");
      done($fh) unless exists $ConDelete{$fh};
      return;
  }
  $friend->{prepend} = '';
  $message = ref($m) ? $$m : $m;

  if (! $friend->{sayMessageOK} && ! $friend->{spamfound}) {
      my $fn;
      &makeSubject($this->{friend}) if ($this->{friend});
      if (! $friend->{maillogfilename}) {
          $fn = Maillog($this->{friend},'',2);
      } else {
          $fn = $friend->{maillogfilename};
      }
      $fn=' -> '.$fn if $fn ne '';
      $fn='' if !$fileLogging;
      my $pr = $friend->{passingreason} ? " - ($friend->{passingreason}) -" : '' ;
      my $logsub = ( $subjectLogging ? " $subjectStart$friend->{originalsubject}$subjectEnd" : '' );
      $friend->{sayMessageOK} = "message ok".de8($pr).$logsub.de8($fn);
  }

  if ($done && ! $friend->{relayok} && $friend->{isbounce} && $friend->{BATVrcpt} && $removeBATVTag) {      # replace BATVTags in header
      my $rcpt = &batv_remove_tag(0,$friend->{BATVrcpt},'');
      mlog($this->{friend},"info: [BATV] removed BATVTag from address $friend->{BATVrcpt} in mailheader: $rcpt") if $BATVLog >= 2;
      my $BATVrcpt = quotemeta($friend->{BATVrcpt});
      $friend->{header} =~ s/$BATVrcpt/$rcpt/ig;
      $message =~ s/$BATVrcpt/$rcpt/ig;
      $friend->{maillength} = length($friend->{header});
  }

  if (! $friend->{addMSGIDsigDone} && $friend->{relayok} && $DoMSGIDsig) { # add the MSGID Tag
      if ($message =~ /(Message-ID\:[\r\n\s]*\<[^\r\n]+\>)/io) {       # if not already done
          my $msgid = $1;
          my $tag = MSGIDaddSig($this->{friend},$msgid);
          if ($msgid ne $tag ) {
              $msgid = quotemeta($msgid);
              $message =~ s/$msgid/$tag/i;
              $friend->{header} =~ s/$msgid/$tag/i;
              $friend->{maillength} = length($friend->{header});
          }
      }
  }

  if ($done && ! $friend->{msgidsigdone} && ! $friend->{relayok} && $friend->{isbounce} && $DoMSGIDsig) {
      return unless (&MSGIDsigOK($this->{friend}));            # check MSGID signature for incoming bounce
  }

  if (! $friend->{MSGIDsigRemoved} && ! $friend->{relayok} && $DoMSGIDsig && ! $this->{noMoreQueued}) {
      if ($friend->{isbounce}) {
          if ($done) {
              &MSGIDsigRemove($this->{friend});  # remove the MSGID signatures from incoming emails
              $friend->{maillength} = length($friend->{header});
          }
      } else {
          &MSGIDsigRemove($this->{friend});  # remove the MSGID signatures from incoming emails
          $friend->{maillength} = length($friend->{header});
      }
  }

  if ($done && $friend->{accBackISPIP}) {   # send 250 OK to ISP if a Backscatter check has failed
      seterror($this->{friend},'250 OK',1);
      return;
  }

#  if (defined($friend->{bdata})) {      # just send binary data
#     sendque($fh,\$message);
#     return;
#  }

  unless ($DoDKIM && $friend->{isDKIM} &&  ! $friend->{relayok}) {
      $message =~ s/\x0D([^\x0A])/\x0D\x0A$1/go;
      $message =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;   # make LF CR RFC conform
  }

  if ($friend->{relayok}) {
      $friend->{ismaxsize} = 1 if ($npSizeOut && $friend->{maillength} >= $npSizeOut);
      $friend->{noprocessing} = 1 if $friend->{ismaxsize};
  } else {
      $friend->{ismaxsize} = 1 if ($npSize && $friend->{maillength} >= $npSize);
      $friend->{noprocessing} = 2 if $friend->{ismaxsize};
  }

  if ($this->{noMoreQueued}) {    # queueing is switched of for some reasons
     $message .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
     sendque($fh,\$message);
     return;
  }

  my ($domain) = $friend->{mailfrom} =~ /^[^@]+\@([^@]+)$/o;
  if (($neverQueueSize && $friend->{maillength} > $neverQueueSize) ||
       (($friend->{ismaxsize} || ($friend->{noprocessing} & 1)) &&
       ! ($genDKIM && $CanUseDKIM && $friend->{relayok} && exists $DKIMInfo{lc $domain}) &&
       ! $runlvl2PL))
  {    # queueing is switched of for some reasons
     $this->{noMoreQueued} = 1;
     if ($this->{qdata}) {
         $friend->{header} .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
         sendque($fh,\$friend->{header});
         delete $this->{qdata};
         if (! ($neverQueueSize && $friend->{maillength} > $neverQueueSize)) {
             if ($friend->{relayok}) {
                 mlog($this->{friend},"info: message reached outgoing noprocessing size $npSizeOut - conversion will be done!") if ($ConvLog && $friend->{ismaxsize});
             } else {
                 mlog($this->{friend},"info: message reached incoming noprocessing size $npSize - DKIM-check and conversion will be done!") if ($ConvLog && $friend->{ismaxsize});
             }
         } else {
             mlog($this->{friend},"info: message is too large ( > neverQueueSize $neverQueueSize byte) to be queued for further internal processing! Skipping DKMI, Plugins and charset conversion.");
         }
     } else {
         $message .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
         sendque($fh,\$message);
     }
     &sayMessageOK($this->{friend});
     return;
  }

  if (! $friend->{isbounce} &&
      ! $CanUseEMM &&
      ! $runlvl2PL &&
      ! $genDKIM &&
      (! $DoDKIM || ($DoDKIM && (! $friend->{isDKIM} || $friend->{relayok})))) {    # Email::MIME::Modfier is not installed

     $this->{noMoreQueued} = 1;
     if ($this->{qdata}) {
         $friend->{header} .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
         sendque($fh,\$friend->{header});
         delete $this->{qdata};
     } else {
         $message .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
         sendque($fh,\$message);
     }
     &sayMessageOK($this->{friend});
     return;
  }

  if ($friend && $friend->{relayok}) {    # this is outbound if relayok for friend
    if ($outChrSetConv) {
     $convert=1;
     %oldchrset=%outchrset;
     d('outbound charset conversion is set to on');
    }
    if($CanUseTNEF && $doOutFixTNEF) {
       $doFixTNEF = $doOutFixTNEF;
       $keepTNEF = $keepOutTNEF;
       $convert=1;
    }
  } elsif ($friend) {   #convert inbound mail
    if ($inChrSetConv) {
     $convert=1;
     %oldchrset=%inchrset;
     d('inbound charset conversion is set to on');
    }
    if($CanUseTNEF && $doInFixTNEF) {
       $doFixTNEF = $doInFixTNEF;
       $keepTNEF = $keepInTNEF;
       $convert=1;
    }
  }
  if (! $friend->{isbounce} &&
      $done &&
      ! $convert &&
      ! $runlvl2PL &&
      ! $genDKIM &&
      (! $DoDKIM || ($DoDKIM && (! $friend->{isDKIM} || $friend->{relayok})))) {    # no conversion to do

     $this->{noMoreQueued} = 1;
     if ($this->{qdata}) {
         $friend->{header} .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
         sendque($fh,\$friend->{header});
         delete $this->{qdata};
     } else {
         $message .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
         sendque($fh,\$message);
     }
     &sayMessageOK($this->{friend});
     return;
  }

  if ($TNEFDEBUG) {
#    $friend->{prepend} = "[conversion]";
    mlog($this->{friend},"info: queued first data in sendqueue") if (! exists $this->{qdata} && $ConvLog);
  }

  $this->{qdata} = 1 if (! exists $this->{qdata});

  if (! $done) {
      my $length = length($friend->{header});
      if (eval {require Convert::Scalar;} && $friend->{ismaxsize} && ! $friend->{SIZE} && (! $this->{allocmem} || int($length / 1000000) > $this->{allocmem})) {
          my $length = length($friend->{header});
          my $nlength = 1 + int($length / 1048576);
          my $slength = $nlength * 1048576;
          $length = &formatNumDataSize($length);
          grow(\$friend->{header} , $slength);
          grow(\$this->{outgoing} , $slength);
          if ($friend->{maillogbuf}) {
              my $mlbufsize = max(($MaxBytes ? $MaxBytes + 1024 : 0),
                                  ($StoreCompleteMail >= $slength ? $slength : 0)
                                 );
              grow(\$friend->{maillogbuf} , $mlbufsize) if $mlbufsize;
          }
          if ($ConTimeOutDebug) {
              grow(\$friend->{contimeoutdebug} , $slength);
          }

          $this->{allocmem} = $nlength;
          mlog($this->{friend}, "info: allocated $nlength MB memory for large message (currently $length).") if $ConnectionLog > 2;
      }
      my $timeout = $smtpIdleTimeout || 180;   # send some data to the server to prevent SMTP-timeout
      if ($this->{lastwritten} && time - $this->{lastwritten} > $timeout) {
          $this->{lastwritten} = time;
          my $dummy = "X-ASSP-KEEP:\r\n";
          sendque($fh,\$dummy);
      }
      return ;                         # queue the data until all data are received
  }

  delete $this->{noMoreQueued};
  delete $this->{qdata};

  d('convert and send data');
  mlog($this->{friend},"convert and send data from sendqueue") if ($TNEFDEBUG);

  unless ($DoDKIM && $friend->{isDKIM} &&  ! $friend->{relayok}) {
      $friend->{header} =~ s/\x0D([^\x0A])/\x0D\x0A$1/go;
      $friend->{header} =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;   # make LF CR RFC conform
  }

  if ($DoDKIM && $friend->{isDKIM} &&  ! $friend->{relayok} && ! $friend->{noprocessing}) {
      eval{$DKIMres = DKIMOK($this->{friend},\$friend->{header},defined${chr(ord(",")<< 1)});};
      if (! $@) {
        if (! $DKIMres ) {   # DKIM check has failed -> this is SPAM
           $friend->{skipmaillog} = 0;
           delete $friend->{messagelow};
           &MaillogRemove($friend);
           $friend->{detectonly} = 1;
           my $isspam = thisIsSpam($this->{friend},$friend->{messagereason},$DKIMLog,"554 DKIM signature failed",$dkimTestMode,0,1);
           $friend->{detectonly} = '';
           mlog($this->{friend}," -\> ".de8($friend->{maillogfilename})) if($friend->{maillogfilename});
           if ($isspam) {
             unless ($friend->{spamlover} & 1 ) {$Stats{dkim}++;}
             return;
           }
        } elsif ($DKIMres == 1) {  # this is no DKIM or is not checked for any reason
        } elsif ($DKIMres == 2) {  # DKIM check has passed -> we can not convert (modify) the mail
           if ($DoDKIM == 3) {
               $friend->{TestMessageScore} = 1;
               delete $friend->{messagescoredone};
               my $maillogparm = $friend->{maillogparm};
               if (&TestMessageScore($this->{friend})) {  # check the score if DoDKIM == 3
                    $friend->{skipmaillog} = 0;
                    delete $friend->{messagelow};
                    &MaillogRemove($friend);
                    $friend->{detectonly} = 1;
                    my $isspam = MessageScore($this->{friend},1);
                    $friend->{detectonly} = '';
                    delete $friend->{TestMessageScore};
                    if ($isspam) {
                      return;
                    }
               }
               delete $friend->{TestMessageScore};
               $friend->{messagescoredone} = 1;
               $friend->{maillogparm} = $maillogparm;
           }
           # message is OK
           $headlen = index($friend->{header}, "\x0D\x0A\x0D\x0A");  # merge header
           $friend->{header} = substr($friend->{header},0,$headlen)."\r\nX-Assp-DKIM: $friend->{dkimverified}".substr($friend->{header},$headlen,length($friend->{header})-$headlen) if ($AddDKIMHeader and $headlen > 2);
           $friend->{skipmaillog} = 0;
           $friend->{maillogparm} = 2 if (! $friend->{maillogparm});
           Maillog($this->{friend},'',$friend->{maillogparm});
           delete $friend->{maillogparm};
           if (! $doDKIMConv && ! $runlvl2PL) {
              $friend->{header} .= "\x0D\x0A.\x0D\x0A" if $done && ($friend->{header} !~ /\x0D\x0A\.\x0D\x0A$/o);
              sendque($fh,\$friend->{header});
              &sayMessageOK($this->{friend});
              return;
           }
        }
      } else {
        my $error = $@;
        mlog($this->{friend},"ERROR: DKIM check cause an exception - $error") if $ValidateSenderLog;
        $friend->{skipmaillog} = 0;
        $friend->{maillogparm} = 2 if (! $friend->{maillogparm});
        Maillog($this->{friend},'',$friend->{maillogparm});
        delete $friend->{maillogparm};
        if (! $doDKIMConv && ! $runlvl2PL) {
           $friend->{header} .= "\x0D\x0A.\x0D\x0A" if $done && ($friend->{header} !~ /\x0D\x0A\.\x0D\x0A$/o);
           sendque($fh,\$friend->{header});
           &sayMessageOK($this->{friend});
           return;
        }
      }
  }

  if ($runlvl2PL){
#   @plres = [0]result,[1]data,[2]reason,[3]plLogTo,[4]reply,[5]pltest,[6]pl
    my @plres = &callPlugin($this->{friend},2,\$friend->{header});  # call the runlevel 2 Plugins
    if ($plres[0]) {  # check scoring if OK
       @plres = MessageScorePL($this->{friend},@plres);
    }
    if (! $plres[0]) {  # we've got an error
        my $slok=$friend->{spamLovers}==1;
        headerUnwrap($friend->{myheader});
        makeMyheader($this->{friend},$slok,$plres[5],$plres[2]);
        $friend->{myheader} =~ s/^[\r\n]+//o;
        $friend->{myheader} =~ s/[\r\n]+$//o;

        addMyheader($this->{friend}) if $friend->{myheader};

        $friend->{skipmaillog} = 0;
#        my $wasremoved = &MaillogRemove($friend);     # switch the maillog to spam
#        mlog($this->{friend}," -\> ".de8($friend->{maillogfilename})) if($friend->{maillogfilename});
        my $t = $plres[2] =~ /MessageScore \d+, limit \d+/io ? 'by MessageScore-check after' : 'by';
        mlog($this->{friend},"mail blocked $t Plugin $plres[6] - reason $plres[2]");
        $friend->{detectonly} = 1;
        $friend->{messagelow} = &TestLowMessageScore($this->{friend});
        my $isspam = thisIsSpam($this->{friend},$plres[2],$plres[3],$plres[4],$plres[5],$slok,$done);
        $friend->{detectonly} = '';
        if ($isspam) {      # no testmode
           return;
        }
    }
  }

  if (! $doDKIMConv && $friend->{isDKIM}) {
        $friend->{header} .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(?:\x0D?\x0A)+$/o;
        sendque($fh,\$friend->{header});
        &sayMessageOK($this->{friend});
        return;
  }

  &sayMessageOK($this->{friend});

  $friend->{prepend} = '';

if ((! $friend->{noprocessing} || $convertNP) && $convert && ! $friend->{signed}) {
  my $newmail;
  eval {
  $time=Time::HiRes::time();
  $convert=0;
  if ($inChrSetConv || $outChrSetConv) {                             # convert the MIME header if possible and needed
      $headlen = index($friend->{header}, "\x0D\x0A\x0D\x0A");
      $headlen = 0 if $headlen < 0;
      d("headlen: $headlen");
      if (substr($friend->{header},0,$headlen) =~ /Content-Transfer-Encoding:\s*(?:[78]bit|binary)\s*\x0D\x0A/io) {;
         $mimestr = $1;                 # if there is CTE there must be CT with charset...
         $pos=index($friend->{header}, $mimestr, 0);
         if (substr($friend->{header},0,$headlen) !~ /Content-Type:[^;]+;.*?charset\s*=\s*[\"\']?[^\"\']*?[\"\']?/io) {
            substr($friend->{header},$pos,length($mimestr),'');  # remove worth CTE it's us-ascii 7/8bit
            d("removed worth CTE $mimestr from header - no corresponding charset statement found");
            mlog($this->{friend},"removed worth CTE $mimestr from header - no corresponding charset statement found") if ($TNEFDEBUG);
         }
      }
      $pos=0;
      while ($pos < $headlen) {
        last if (substr($friend->{header},$pos,$headlen-$pos) !~ /(=\?([^?]*)\?([bq])\?[^?]+\?=)/io);     # get charset and encoding
        $mimestr=$1;
        d("mimestr: $mimestr");
        $newpos=index($friend->{header}, $mimestr, $pos);
        d("pos: $newpos");
        $name = Encode::resolve_alias(uc($2));
        $enc = uc($3);
        if(exists $oldchrset{$name}) {
          $newchrset = $oldchrset{$name};
          $newchrset = 'UTF-8' if ($newchrset =~ /utf8|utf-8/io);
          d("org $name head: $mimestr");
          $newmimestr = decodeMimeWords($mimestr);
          d('dec native head: hex '.unpack( "H*", $newmimestr));
          $newmimestr=Encode::encode($newchrset,$newmimestr);
          d("enc native $newchrset head: hex ".unpack( "H*", $newmimestr));
          $newmimestr = encodeMimeWord($newmimestr, $enc, $newchrset);
          $newmimestr =~ s/ /_/go if ($enc =~ /q/io);    # if spaces are not well encoded
          d("enc $newchrset head: $newmimestr");
          substr($friend->{header},$newpos,length($mimestr),$newmimestr);      # put the new MIME in header
          mlog($this->{friend},"info: done header conversion from $name to $newchrset") if $ConvLog && !$convert;
          $convert=1;
          $pos=$newpos+length($newmimestr);
        } else {
          $pos=$newpos+length($mimestr);
        }
      }
  }

  my @convParts;
  $i=0;
  $o_EMM_pm = 1;
  $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
  $email = Email::MIME->new($friend->{header});
  foreach my $part ( $email->parts ) {
    $i++;
    $name = attrHeader($part,'Content-Type','charset');
    $boundary = attrHeader($part,'Content-Type','boundary');
    $name=Encode::resolve_alias(uc($name)) if $name;
    if ( exists $oldchrset{$name} && $part->header("Content-Type")=~/text\//io) {   # if the part is 'text' and a conversiontable entry exists
          $convert |= 1;
          $newchrset=$oldchrset{$name};
          $newchrset = 'UTF-8' if ($newchrset =~ /utf8|utf-8/io);
          mlog($this->{friend},"character set conversion: from $name to $newchrset in MIME part $i") if $ConvLog;
          $body = $part->body;
          $body = Encode::decode($name,$body);
          $body = Encode::encode($newchrset, $body);
          $part->body_set( $body );
          $part->charset_set($newchrset);
          $part->encoding_set('quoted-printable') if ! is_7bit_clean(\$part->body);
    } elsif ($doFixTNEF &&
             $CanUseTNEF &&
             $part->header("Content-Type")=~/\/ms-tnef/io &&
             $part->header("Content-Disposition")=~ /attachment|inline/io) {
          mlog($this->{friend},"info: doing ms-tnef conversion") if $ConvLog;
          $enc = $part->header("Content-Transfer-Encoding");
          if ($enc) {
            d("ms-tnef CTE=$enc");
            $add_to_newparts=0 if (! $keepTNEF);
            $body = $part->body;
            $body = Encode::decode($name,$body) if $name;
    	    eval{@TNEFparts = getTNEFparts($body,$enc,%oldchrset)};  # prevent die for unknown data in attachment
            if ($@){
              $add_to_newparts=1;
              mlog($this->{friend},"info: ms-tnef conversion failed for unknown reason") if $ConvLog;
            } else {
              if (! @TNEFparts) {
                $add_to_newparts=1;
                mlog($this->{friend},"info: no convertable ms-tnef parts found in tnef-attachment") if $ConvLog;
              } else {
                while (@TNEFparts) {
                    push(@convParts,
                          Email::MIME->create(
                              attributes => shift @TNEFparts,
                              body => shift @TNEFparts,
                          )
                    );
                }
                mlog($this->{friend},"info: successful finished TNEF conversion") if $ConvLog;
                $convert = 2;
              }
            }
          } else {
            mlog($this->{friend},"info: no Content-Transfer-Encoding information found in header of tnef-part $i") if $ConvLog;
          }
    }
    push(@newparts,$part) if ($add_to_newparts);
    $add_to_newparts=1;
  }
  $email->header_set('MIME-Version', '1.0') if !$email->header('MIME-Version');
  push( @newparts, @convParts ) if @convParts;
  $email->parts_set(\@newparts);
  $newmail = $email->as_string if $convert;

  local $/='';

  if ($TNEFDEBUG && $convert == 2) {     # if TNEFdebug and TNEF converted, print the org and conv email to the file
        d("conversion output to file $base/debug_chrset_conv_parts.txt");
        my $T1;
        open $T1, '>>',"$base/debug_chrset_conv_parts.txt";
        binmode $T1;
        print $T1 "######### original mail ###########\n";
        print $T1 "qdata\n";
        print $T1 "###################################\n";
        print $T1 $friend->{header};
        print $T1 "--------- converted mail ----------\n";
        print $T1 "qdata\n";
        print $T1 "-----------------------------------\n";
        print $T1 $newmail;
        print $T1 "\x0D\x0A.\x0D\x0A" if ($newmail !~ /\x0D\x0A\.\x0D\x0A$/o &&
                                          $friend->{header} =~ /\x0D\x0A\.\x0D\x0A$/o);   # add the dot if the conversion has removed it
        close $T1;
  }
  } ; # end eval
  if ($@){
     my $error = $@;
# if conversion failed send the unconverted
     $friend->{header} .= "\x0D\x0A.\x0D\x0A" if ($friend->{header} !~ /\x0D\x0A\.\x0D\x0A$/o);
     mlog($this->{friend},"info: charset conversion aborted - the unconverted mail is processed\n$error") if $ConvLog;
     if ($TNEFDEBUG) {
        mlog($this->{friend},"conversion-exceptions: $stderr") if ($stderr);
        my $T1;
        open $T1, '>>',"$base/debug_conv_error.txt";
        binmode $T1;
        print $T1 "######### original mail ###########\n";
        print $T1 "qdata\n";
        print $T1 "###################################\n";
        print $T1 $friend->{header};
        print $T1 "--------- error ---------\n";
        print $T1 "qdata\n";
        print $T1 "-------------------------\n";
        print $T1 "$error\n";
        print $T1 "******* exceptions ******\n";
        print $T1 "qdata\n";
        print $T1 "*************************\n";
        print $T1 "$stderr\n";
        close $T1;
     }
     undef $email;
     $o_EMM_pm = 0;
  } else {   # there was no error
     mlog($this->{friend},"info: conversion-exceptions: $stderr") if ($stderr && ($TNEFDEBUG || $ConvLog > 1));
     if ($convert) {   # if conversion was done fix the . at the end of the mail  and the LF problem
       my $addend; $addend = 1 if ($friend->{header} =~ /\x0D\x0A\.\x0D\x0A$/o);
       $friend->{header} = $newmail;
       undef $email;
       $friend->{header} =~ s/\x0D([^\x0A])/\x0D\x0A$1/go;
       $friend->{header} =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;   # make LF CR RFC conform
       $friend->{header} .= "\x0D\x0A.\x0D\x0A" if ($friend->{header} !~ /\x0D\x0A\.\x0D\x0A$/o &&
                                            $addend);   # send the dot if the conversion has removed it
       $time= sprintf("%.3f",(Time::HiRes::time()) - $time) ;
       mlog($this->{friend},"info: MIME/TNEF conversion successful - finished in $time seconds") if $ConvLog;
     } else {
               # send the unconverted there was no conversion
       mlog($this->{friend},"info: no MIME/TNEF conversion done") if ($TNEFDEBUG || $ConvLog > 1);
     }
     undef $email;
     $o_EMM_pm = 0;
  }
} # end convert

  if ($friend->{relayok} && $genDKIM) {
      $friend->{header} =~ s/\x0D([^\x0A])/\x0D\x0A$1/go;
      $friend->{header} =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;   # make LF CR RFC conform
      &DKIMgen($this->{friend});
  }
  $friend->{header} .= "\x0D\x0A\.\x0D\x0A" if $done && $friend->{header} !~ /\x0D?\x0A\.(\x0D?\x0A)+$/o;
  $friend->{maillength} = length($friend->{header});
  sendque($fh,\$friend->{header});
#  &printallCon($fh);
}
