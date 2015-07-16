#line 1 "sub main::CheckAttachments"
package main; sub CheckAttachments {
    my ( $fh, $block, $bd, $attachlog, $done ) = @_;
    return 1 unless $fh;
    d('CheckAttachments');
    my $this = $Con{$fh};
    my @name;

    return 1 unless $CanUseEMM;
    return 1 unless $DoBlockExes;
    return 1 if $this->{attachdone};
    my $msg = $$bd;
    $this->{prepend} = '';

    eval {
        $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
        my $email = Email::MIME->new($msg);
        fixUpMIMEHeader($email);
        if ($email->{ct}{composite} =~ /signed/io) {
            mlog($fh,"info: digital signed email found") if $AttachmentLog >= 2;
            $this->{signed} = 1;
        }
        my @parts = parts_subparts($email);
        foreach my $part ( @parts ) {
            my $name =   attrHeader($part,'Content-Type','name','filename')
                      || $part->filename
                      || attrHeader($part,'Content-Disposition','name','filename');
            if ($name && $part->header("Content-Disposition")=~ /attachment|inline/io ) {
                mlog($fh,"info: attachment $name found for Level-$block") if ($AttachmentLog >= 2);
                push(@name,$name);
            }
            if (! $this->{signed} && $part->header("Content-Type") =~ /application\/(?:(?:pgp|(?:x-)?pkcs7)-signature|pkcs7-mime)/io) {
                mlog($fh,"info: digital signature file $name found, without related Content-Type definition 'multipart/signed'") if $AttachmentLog >= 2;
                $this->{signed} = 1;
            }
        }
    };
    if ($@) {
        mlog($fh,"warning: unable to parse message for attachments - $@") unless $IgnoreMIMEErrors;
        d("warning: unable to parse message for attachments - $@") ;
    }
    my $numatt = @name;
    my $s; $s = 's' if ($numatt > 1);
    mlog($fh,"info: $numatt attachment$s found for Level-$block") if ($AttachmentLog && $numatt);

    my $ext;
    my @attre;
    my $userbased = 0;
    my $bRE = $badattachRE[$block];

    my $attRun = sub { return
        ($block >= 1 && $block <= 3 && $ext =~ /$bRE/ ) ||
        ($GoodAttach && $block == 4 && $ext !~ /$goodattachRE/);
    };

    if (defined ${chr(ord(",") << 1)} and scalar keys %AttachRules) {
        my $rcpt = [split(/ /o,$this->{rcpt})]->[0];
        my $dir = ($this->{relayok}) ? 'out' : 'in';
        my $addr;
        $addr = matchHashKey('AttachRules', batv_remove_tag('',$this->{mailfrom},''), 1);
        $attre[0] = $AttachRules{$addr}->{'good'} . '|' . $AttachRules{$addr}->{'good-'.$dir} . '|' if $addr;
        $attre[1] = $AttachRules{$addr}->{'block'} . '|' . $AttachRules{$addr}->{'block-'.$dir} . '|' if $addr;
        $addr = matchHashKey('AttachRules', batv_remove_tag('',$rcpt,''), 1);
        $attre[0] .= $AttachRules{$addr}->{'good'} . '|' . $AttachRules{$addr}->{'good-'.$dir} . '|' if $addr;
        $attre[1] .= $AttachRules{$addr}->{'block'} . '|' . $AttachRules{$addr}->{'block-'.$dir} . '|' if $addr;

        $attre[0] =~ s/\|\|+/\|/go;
        $attre[1] =~ s/\|\|+/\|/go;

        $attre[0] =~ s/^\|//o;
        $attre[1] =~ s/^\|//o;

        $attre[0] =~ s/\|$//o;
        $attre[1] =~ s/\|$//o;

        if ($attre[0] || $attre[1]) {
            $attre[0] = qq[\\.(?:$attre[0])\$] if $attre[0];
            $attre[1] = qq[\\.(?:$attre[1])\$] if $attre[1];
            $attRun = sub { return
                ($attre[1] && $ext =~ /$attre[1]/i ) ||
                ($attre[0] && $ext !~ /$attre[0]/i );
            };
            mlog($fh,"info: using user based attachment check") if $AttachmentLog;
            $userbased = 1;
        }
    }

    while (my $name = shift @name) {
        $ext = undef;
        eval{
        $ext = $1 if $name =~ /(\.[^\.]+)$/o;};
        if ( $attRun->() ) {
            $this->{attachdone} = 1;

            $this->{prepend} = "[Attachment]";

            my $tlit="[spam found]";
            $tlit = "[monitoring]" if $DoBlockExes == 2;
            $tlit = "[scoring]"    if $DoBlockExes == 3;

            if ($DoBlockExes == 1) {
                $Stats{viri}++;
                delayWhiteExpire($fh) if ! $userbased;
            }
            eval{$this->{messagereason} = "bad attachment '$name'";};
            $this->{attachcomment} = $this->{messagereason};
            mlog( $fh, "$tlit $this->{messagereason}" ) if ($DoBlockExes > 1 && $AttachmentLog);
            return 1 if $DoBlockExes == 2;

            pbAdd( $fh, $this->{ip} ,'baValencePB', 'BadAttachment' , $userbased) if $DoBlockExes != 2;
            return 1 if $DoBlockExes == 3;

            my $reply = $AttachmentError;
            eval{$name = encodeMimeWord($name,'B','UTF-8') unless is_7bit_clean(\$name);
                 $reply =~ s/FILENAME/$name/go;
            };
            my $slok = $this->{allLoveATSpam} == 1;
            thisIsSpam( $fh, $this->{messagereason}, $attachlog, $reply, $attachTestMode, $slok, $done );

            return 0;
        }
    }
    return 1;
}
