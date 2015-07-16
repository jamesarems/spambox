#line 1 "sub main::is_7bit_clean"
package main; sub is_7bit_clean {
    my $ref = shift;
#    return $$ref =~ /^\p{ASCII}*$/o;
    my $ret;
    eval('
    use bytes;
    $ret = ${$ref} !~ /[^\x20-\x7F\x0A\x0D\t]/os;
    no bytes;');
    return $ret;
}
