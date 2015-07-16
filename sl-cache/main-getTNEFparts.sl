#line 1 "sub main::getTNEFparts"
package main; sub getTNEFparts {

    my ($body,$dec,%oldchrset) = @_;
    my @retval;
    my $fh;
    my $msg;
    my $cp;
    my $mc;
    my $ext;
    my $mimetypes;
    my $type;
    my $c;
    my $nc;
    my $encoding;
    my $att;
    my $ln;
    my $tnef;
    my %parms=('output_to_core' => 'ALL', 'debug' => $TNEFDEBUG);
    mlog(0,"info: try to convert TNEF-part");
#    $body = Email::MIME::Encodings::decode($dec => $body);
    unless (open( $fh, '<', \$body)) {
        mlog(0,"error: TNEF-conversion error - unable to open MIME content");
        return @retval;
    }
    $tnef = Convert::TNEF->read($fh, \%parms )  ;
    if (! $tnef) {
        my $err = $Convert::TNEF::errstr;
        mlog(0,'error: TNEF-conversion error - ' . $Convert::TNEF::errstr);
        close $fh;
        return @retval;
    }

    for ($tnef->message) {
        $msg = $_;
        next if (!exists $msg->{MessageClass});
        eval{$cp= $msg->{OemCodepage}->data;};
        $nc = "CP437";
        if ( $cp ) {
            $cp= unpack('H*',$cp);
            $cp=256*hex(substr($cp,2,2))+hex(substr($cp,0,2));
            $cp="CP$cp";
            $cp=Encode::resolve_alias(uc($cp)) ;
            $nc = $oldchrset{$cp};
            $nc = 'UTF-8' if ($nc =~ /utf8|utf-8/io);
            $nc = $cp if (! $nc);
        }
        $mc=$msg->{MessageClass}->data;
        if ( $mc ) {
            $mc=~s/\000//go;
            $mc=~/^[\w\W]+\.([a-zA-Z0-9]{2,4})$/o;
            $ext = $1;
            $mimetypes = MIME::Types->new;
            $type = $mimetypes->mimeTypeOf($ext);
        }
        eval{$c = $msg->{Body}->data;};
        $c =~ s/\000//og;
        if ($nc && $cp && $c) {
            $c = Encode::decode($cp,$c);
            $c = Encode::encode($nc,$c);
        }
        $type = "text/plain" if (! $type);
        $encoding = 'quoted-printable';
        if ($c) {
#            $c = Email::MIME::Encodings::encode($encoding => $c);
            push(@retval ,
                  {content_type => $type,
                   encoding     => $encoding,
                   charset      => $nc
                  }
            );
            push(@retval,$c);
            d('added message part from TNEF to MIME');
            mlog(0,'added message part from TNEF to MIME');
        }
    }
    for ($tnef->attachments) {
        $att = $_;
        eval{$ln = $att->longname;};
        $c='';
        $cp = '';
        $nc = "CP437";
        $type = '';
        $ln=~/^[\w\W]+\.([A-Za-z0-9]{2,4})$/o;
        $ext = $1;
        $mimetypes = MIME::Types->new;
        $type = $mimetypes->mimeTypeOf($ext) if ($ext);
        if ($type) {
            if ($type =~ m,^text/,o) {
                $encoding = 'quoted-printable';
            } else {
                $encoding = 'base64';
            }
        } elsif ($att->data =~ /[^\t\n\r\f\040-\177]/o) {
            $encoding = 'base64';
            $type = "application/octet-stream";
        } else {
            $encoding = 'quoted-printable';
        }
#        eval{$c = Email::MIME::Encodings::encode($encoding => $att->data) if ($att->data);};
        $c = $att->data if ($att->data);
        if ($encoding eq 'quoted-printable') {
            $type = 'text/plain' if (! $type);
            eval{$cp= $att->{OemCodepage}->data;};
            if ($cp) {
                $cp= unpack('H*',$cp);
                $cp=256*hex(substr($cp,2,2))+hex(substr($cp,0,2));
                $cp="CP$cp";
            } else {
                $cp = 'UTF-8';
            }
            $cp=Encode::resolve_alias(uc($cp)) ;
            $nc=$cp;
            $nc = $oldchrset{$cp} if (exists $oldchrset{$cp});
            $nc = 'UTF-8' if ($nc =~ /utf8|utf-8/io);
            if ($nc && $cp && $c) {
                $c = Encode::decode($cp,$c);
                $c = Encode::encode($nc,$c);
            }
        }
        if ($c) {
            if ($encoding eq 'quoted-printable') {
                push(@retval ,
                      {
                       content_type => $type,
                       encoding     => $encoding,
                       charset      => $nc
                      }
                );
            } else {
                push(@retval ,
                      {
                       content_type => $type,
                       encoding     => $encoding,
                       charset      => $nc,
                       disposition  => 'attachment',
                       filename     => $ln,
                       name         => $ln
                      }
                );
            }
            push(@retval,$c);
            d("added attachment part $ln from TNEF to MIME");
            mlog(0,"added attachment part $ln from TNEF to MIME");
        }
    }
    $tnef->purge;
    close $fh;
    return @retval;
}
