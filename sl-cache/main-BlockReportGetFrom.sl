#line 1 "sub main::BlockReportGetFrom"
package main; sub BlockReportGetFrom {
    my ($fn,$fl,$showaddr) = @_;
    my $res;
    my $bodyhint;
    my $foundbody;
    my $headerseen;
    return unless ($open->(my $F,'<' ,$fn));
    while (<$F>) {
        s/\r|\n//go;
        $headerseen = 1 if (! $_);  # header only
        if ($headerseen && $_) {
            $foundbody = 1;
            last;
        }
        next unless $showaddr;
        my ($tag,$adr);
        ($tag,$adr) = ($1,$2) if /^(from|sender|reply-to|errors-to|list-\w+:)[^\r\n]*?($EmailAdrRe\@$EmailDomainRe)/io;
        next unless ($tag && $adr);
        next if $$fl =~ /\Q$adr\E/i;
        $tag = &encHTMLent(\$tag);
        $adr = &encHTMLent(\$adr);
        $res .= '<span name="tohid" class="addr"><br />'. $tag . '&nbsp;&nbsp;' . $adr . '</span>';
    }
    $F->close;
    $bodyhint = '<br /><small>no message body received</small>' unless $foundbody;
    return ($res,$bodyhint);
}
