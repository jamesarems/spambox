#line 1 "sub main::AttachMD5File"
package main; sub AttachMD5File {
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
    return AttachMD5Mail(\$msg);
}
