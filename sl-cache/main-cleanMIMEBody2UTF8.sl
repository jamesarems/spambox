#line 1 "sub main::cleanMIMEBody2UTF8"
package main; sub cleanMIMEBody2UTF8 {
    my $m = shift;
    my $msg = ref($m) ? $$m : $m;
    return unless $msg;
    $msg =~ s/([^\x0D])\x0A/$1\x0D\x0A/go;
    my $body;
    my %cs;
    my $oe = $o_EMM_pm;
    $o_EMM_pm = 1 if $msg =~ /[\r\n]\.[\r\n]+$/os;

#open(my $F,'>',"$base/debug/body.".Time::HiRes::time.'.txt');
#binmode $F;
#(my $package, my $file, my $line, my $Subroutine, my $HasArgs, my $WantArray, my $EvalText, my $IsRequire) = caller(0);
#print $F "<caller>$package, $file, $line, $Subroutine<caller>\n";
#print $F '<msg>'.$msg."<msg>\n\n";

    eval {
        local $SIG{ALRM} = sub { die "__alarm__\n"; };
        alarm(30);
        $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
        my $email = Email::MIME->new($msg);
        fixUpMIMEHeader($email);
        my @allParts = parts_subparts($email);
#print $F '<addCharsets>'.$addCharsets."<addCharsets>\n";
#print $F '<parts>'.scalar(@allParts)."<parts>\n";
        foreach my $part ( @allParts ) {
            my ($cs, $dis, $odis);
            $dis = $odis = $part->header("Content-Type") || '';
            next if $part->header("Content-ID") && $dis !~ /text/oi;    # no inline images / app's
            my $name = attrHeader($part,'Content-Type','name','filename') || $part->filename;
            $cs = attrHeader($part,'Content-Type','charset');
            $cs{uc $cs} = "charset=$cs" if $cs;
#print $F '<charset>'.$cs."<charset>\n" if $cs;
#print $F '<name>'.$name."<name>\n" if $name;
            eval {
                $cs =~ s/^[^A-Za-z]+//o;
                $cs =~ s/[^A-Za-z0-9_\-]+.*$//o;
                if ( my $acs = Encode::resolve_alias(uc($cs)) ) {
                    $cs{uc $acs} = "charset=$acs" if uc($acs) ne uc($cs);
                } else {
                    $cs{'UNKNOWN'} = "charset=UNKNOWN";
                    $cs = undef;
                }
            } if $cs && ! $name;
            if (! $name && ! $addCharsets) {
                $name = attrHeader($part,'Content-Disposition','name','filename');
            }

            my $bd;
#mlog(0,"info: addCharsets:$addCharsets , name:$name , $odis, $dis, $o_EMM_pm , ". \&parts_multipart .' '. \&Email::MIME::parts_multipart);
            if (! $addCharsets) {
                if ($name) {
                    $bd = "\r\nattachment:$name\r\n";
                    $bd .= $part->body if $odis =~ /text/oi;
                } else {
                    $bd = $part->body;
                }
                if ($bd && $cs) {
                    $cs .= endian(\$bd,uc($cs)) if uc($cs) =~ /^(?:UTF[_-]?(?:16|32)|UCS[_-]?[24])$/o;
                    $bd = Encode::decode($cs, $bd);
                    $bd = e8($bd);
                }
            }
            $body .= "\r\n" if ! $addCharsets && $body && $bd && $body !~ /\r?\n$/o && $bd !~ /^\r?\n/o;
            $body .= $bd;
#print $F '<bd>'.$bd."<bd>\n";
        }
        if ($addCharsets) {
            my @mime_coded;
            eval {@mime_coded = $msg =~ /=\?([a-zA-Z0-9\-]{2,20})\?[bq]\?/iog;
                  map {
                          my $t = $_;
                          $t =~ s/[\r\n\s]+//go;
                          my $acs = Encode::resolve_alias(uc($t));
                          $cs{uc $t} = "charset=$t" if $acs;
                      } @mime_coded;
                 };
        }
        if (! $body) {
#print $F '<nobody>'."<nobody>\n";
            my $cs = attrHeader($email,'Content-Type','charset');
            $cs{uc $cs} = "charset=$cs" if $cs;
            $body = $email->body if (! $addCharsets && $email->header("Content-Type") =~ /text/oi);
            eval {
                $cs =~ s/^[^A-Za-z]+//o;
                $cs =~ s/[^A-Za-z0-9_\-]+.*$//o;
                if ( my $acs = Encode::resolve_alias(uc($cs)) ) {
                    $cs{uc $acs} = "charset=$acs" if uc($acs) ne uc($cs);
                } else {
                    $cs{'UNKNOWN'} = "charset=UNKNOWN";
                    $cs = undef;
                }
            } if $cs;
            if ($body && $cs && ! $addCharsets) {
                $cs .= endian(\$body,uc($cs)) if uc($cs) =~ /^(?:UTF[_-]?(?:16|32)|UCS[_-]?[24])$/o;
                $body = Encode::decode($cs, $body);
                $body = e8($body);
            }
        }
        $body = join("\n", values %cs)."\n" if scalar keys %cs && $addCharsets;
        alarm 0;
    } if $CanUseEMM;
    alarm 0;
    mlog(0,"warning: UTF8 conversion for message body timed out (30s)") if $@ =~ /__alarm__/io;
    mlog(0,"warning: message MIME processing failed - $@") if $@ && $@ !~ /__alarm__/io;
    $o_EMM_pm = $oe;
#print $F '<body>'.$body."<body-stop>\n";
#close $F;
    return $body;
}
