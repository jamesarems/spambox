#line 1 "sub main::mlog_i"
package main; sub mlog_i {
    my ( $fh, $comment, $noprepend, $noipinfo ) = @_;
    mlog( $fh, $comment, $noprepend, $noipinfo );
    &mlogWrite() if $WorkerNumber == 0;
}
