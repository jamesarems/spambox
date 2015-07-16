#line 1 "sub main::getMD5File"
package main; sub getMD5File {
    my $fn = shift;
    return unless $fn;
    return unless $eF->( $fn );
    return if $dF->( $fn );
    return unless $CanUseMD5Keys;
    my $msg;
    $open->(my $F,'<', $fn ) or return;
    $F->binmode;
    $F->read($msg,[$stat->($fn)]->[7]);
    $F->close;
    return Digest::MD5::md5_hex($msg);
}
