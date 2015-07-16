#line 1 "sub main::headerFormat"
package main; sub headerFormat {
    my $text = shift;
    $text =~ s/(?:\r*\n)+/\r\n/gos;
    return headerWrap($text) if &is_7bit_clean(\$text);
    my $org = $text;

    eval{
         $text = join("\r\n", map{headerWrap(MIME::Words::encode_mimewords(&decodeMimeWords2UTF8($_),('Charset' => 'UTF-8')));} split(/\r?\n/o,$text));
         $text .= "\r\n" if $text !~ /\r\n$/o;
    };

    if ($@) {
       my $hint; $hint = "- **** please install the Perl module MIME::Tools (includes MIME::Words) via 'cpan install MIME::Tools' (on nix/mac) or 'ppm install MIME-Tools' (on win32)"
           if $@ =~ /Undefined subroutine \&MIME::Words::encode_mimewords/io;
       mlog(0,"warning: MIME encoding for our SPAMBOX header lines failed - $@ $hint") if ! $IgnoreMIMEErrors;
       eval{
           $text = join("\r\n", map{headerWrap(&encodeMimeWord(&decodeMimeWords2UTF8($_),'B','UTF-8'));} split(/\r?\n/o,$text));
           $text .= "\r\n" if $text !~ /\r\n$/o;
       };
       if ($@) {
           $org .= "\r\n" if $org;
           $org =~ s/(?:\r?\n)+/\r\n/go;
           return $org;
       }
    }
    $text =~ s/\=\?UTF\-8\?Q\?\=20\?\=/ /gio;    # revert unneeded MIME-encoding of a single space ????
    $text =~ s/\=\?UTF\-8\?Q\?\?\=//gio;    # revert unneeded MIME-encoding of an empty line ????
    $text .= "\r\n" if $text;
    $text =~ s/(?:\r?\n)+/\r\n/go;
    return $text;
}
