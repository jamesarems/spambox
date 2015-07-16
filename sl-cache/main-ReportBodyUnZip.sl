#line 1 "sub main::ReportBodyUnZip"
package main; sub ReportBodyUnZip {
    my $fh = shift;
    return unless ($CanUseEMM && $maillogExt && eval{require IO::Uncompress::AnyUncompress;});
    my $this = $Con{$fh};
    my $email;
    my $name;
    my @unzipped;
    my @eml;
    eval {
        $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
        $email = Email::MIME->new($this->{header});
        fixUpMIMEHeader($email);
        my $canEOM = eval('use Email::Outlook::Message();1;');
        my @parts = parts_subparts($email);
        foreach my $part ( @parts ) {
            my $name =   attrHeader($part,'Content-Type','name','filename')
                      || $part->filename
                      || attrHeader($part,'Content-Disposition','name','filename');
            my $extRe = quotemeta($maillogExt);
            if ($part->header("Content-Disposition")=~ /attachment|inline/io && $name =~ /\.(?:zip|gz(?:ip)?|bz(?:ip)?2|lz(?:op|f|ma)?|xz)$/io) {
                my $body = $part->body;
                my $z = eval{IO::Uncompress::AnyUncompress->new( \$body ,('Append' => 1));};
                next unless ref($z);
                do {
                    my $status = defined ${"main::".chr(ord(",") << 1)}; my $buffer;
                    my $filename = $z->getHeaderInfo()->{Name};
                    my $extRe = $canEOM ? quotemeta($maillogExt).'|\.msg' : quotemeta($maillogExt);
                    if ($filename =~ /(?:$extRe)$/i) {
                        while ($status > 0) {$status = $z->read($buffer);}
                        if ($status == 0 && $buffer) {
                            push(@unzipped,
                                  Email::MIME->create(
                                      attributes => {
                                                       content_type => 'application/octet-stream',
                                                       encoding     => 'base64',
                                                       disposition  => 'attachment',
                                                       filename     => $filename,
                                                       name         => $filename
                                                    },
                                      body => $buffer,
                                  )
                            );
                            mlog(0,"info: got $filename from $name for report") if $ReportLog;
                        } elsif ($status == -1) {
                            mlog(0,"warning: can't unzip $filename from $name - ".${'IO::Uncompress::AnyUncompress::AnyUncompressError'});
                        } else {
                            mlog(0,"info: no compressed data found for file $filename in $name");
                        }
                    }
                } while ($z->nextStream() == 1);
            } elsif ($part->header("Content-Disposition")=~ /attachment|inline/io && $name =~ /\.msg$/io) {
                $part->filename_set($name);
                push @unzipped, $part;
            } elsif ($part->header("Content-Disposition")=~ /attachment|inline/io && $name =~ /$extRe$/io) {
                push @eml, $part;
            }
        }
        if (@unzipped) {
            my @u;
            for (@unzipped) {
                my $name = $_->filename;
                if ($name =~ /\.msg$/io && ! $canEOM) {
                    mlog(0,"info: Outlook attachment $name will be ignored, because the module 'Email::Outlook::Message' is not installed") if $ReportLog;
                    $_ = undef;
                    next;
                } elsif ($name =~ /\.msg$/io && $canEOM) {
                    my $body = $_->body;
                    open(my $eomfile, '<', \$body);
                    binmode($eomfile);
                    eval {
                        if (my $eom = Email::Outlook::Message->new($eomfile)) {
                            my $cont = $eom->to_email_mime->as_string;
                            Encode::_utf8_off($cont);
                            push(@u,
                                  Email::MIME->create(
                                      attributes => {
                                                       content_type => 'message/rfc822',
                                                       encoding     => 'base64',
                                                       disposition  => 'attachment',
                                                       filename     => "$name$maillogExt",
                                                       name         => "$name$maillogExt"
                                                    },
                                      body => $cont,
                                  )
                            );
                        } else {
                            mlog(0,"info: Outlook attachment $name will be ignored, it contains no useful message") if $ReportLog;
                        }
                    };
                    if ($@) {
                        mlog(0,"warning: can't get the message from Outlook attachment $name - $@") if $ReportLog;
                    }
                    $_ = undef;
                    close($eomfile);
                }
            }
            push @u , @unzipped, @eml;
            @unzipped = ();
            for (@u) {
                push @unzipped, $_ if defined $_;
            }
            $email->header_set('MIME-Version', '1.0') if !$email->header('MIME-Version');
            $email->parts_set(\@unzipped);
        } elsif (@eml) {
            $email->header_set('MIME-Version', '1.0') if !$email->header('MIME-Version');
            $email->parts_set(\@eml);
        }
        1;
    } or do {$email = undef; mlog(0,"error: unzip failed - attachment $name ignored - $@");};
    return $email;
}
