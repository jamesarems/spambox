#line 1 "sub main::assp_parse_attributes"
package main; sub assp_parse_attributes {
    local $_ = shift;
    my $attribs = {};
    my $tspecials = quotemeta '()<>@,;:\\"/[]?=';
    while ($_) {
        s/^;//o;
        s/^\s+//o and next;
        s/\s+$//o;
        unless (s/^([^$tspecials]+)=\s*//o) {
          # We check for $_'s truth because some mail software generates a
          # Content-Type like this: "Content-Type: text/plain;"
          # RFC 1521 section 3 says a parameter must exist if there is a
          # semicolon.
          $boundaryX = undef;
          mlog(0,"Illegal Content-Type parameter $_") if $_ && ! $IgnoreMIMEErrors && $WorkerNumber != 10001;
          return $attribs;
        }
        my $attribute = $boundaryX = lc $1;
        my $value = assp_extract_ct_attribute_value();
        $attribs->{$attribute} = $value;
    }
    return $attribs;
}
