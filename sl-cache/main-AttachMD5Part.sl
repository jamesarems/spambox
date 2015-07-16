#line 1 "sub main::AttachMD5Part"
package main; sub AttachMD5Part {
    my $part = shift;
    $part = $part->body;
    return unless $part;
    return Digest::MD5::md5_hex(substr($part,0,512)) . ' ' . length($part);
}
