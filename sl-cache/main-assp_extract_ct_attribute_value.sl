#line 1 "sub main::assp_extract_ct_attribute_value"
package main; sub assp_extract_ct_attribute_value {
    my $value;
    my $tspecials = quotemeta '()<>@,;:\\"/[]?=';
    my $vspecials = quotemeta '()<>@,:\\"/[]?=';
    my $extract_quoted =
        qr/(?:\"(?:[^\\\"]*(?:\\.[^\\\"]*)*)\"|\'(?:[^\\\']*(?:\\.[^\\\']*)*)\')/;
    while ($_) {
        s/^([^$tspecials]+)//o and $value .= $1;
        s/^($extract_quoted)//o and do {
            my $sub = $1; $sub =~ s/^["']//o; $sub =~ s/["']$//o;
            $value .= $sub;
        };
        /^;/o and last;
        /^([$tspecials])/o and do {
            if (! $IgnoreMIMEErrors && $WorkerNumber != 10001) {
                mlog(0,"warning: malformed MIME content in '$boundaryX' MIME tag detected - unquoted '$1' not allowed in Content-Type - the tag is ignored!");
                return;
            } else {
                s/^([$vspecials])//o;
                mlog(0,"info: malformed MIME content in '$boundaryX' MIME tag detected - unquoted '$1' not allowed in Content-Type!") if $WorkerNumber != 10001 && $SessionLog > 1;
                $value .= $1;
            }
        }
    }
    return $value;
}
