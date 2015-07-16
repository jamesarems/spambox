#line 1 "sub main::attrHeader"
package main; sub attrHeader {
    my $email = shift;
    my $tag = shift;
    my @attr = @_;
    my $dis = $email->header($tag);
    d("header ($tag-attr) : $dis");
    return unless $dis;
    return $dis unless @attr;
    my $attrs;
    $attrs = Email::MIME::ContentType::_parse_attributes($dis) if $dis =~ s/^[^;]*;//o;
    return unless $attrs;
    my $ret;
    for (@attr) {
        $ret = $attrs->{$_} || $email->{ct}{attributes}{$_};
        last if $ret;
    }
    return $ret;
}
