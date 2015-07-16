#line 1 "sub main::BlockReportHTMLTextWrap"
package main; sub BlockReportHTMLTextWrap {
    my $line=shift;
    d('BlockReportHTMLTextWrap');
    return unless $line;

    $line =~ s/\r//go;
    $line =~ s/ +/ /go;
    $line = MIME::QuotedPrint::encode_qp($line);
    $line =~ s/(^|\n)\./$1=2E/gos;
    return $line;
}
