#line 1 "sub main::mlog_S"
package main; sub mlog_S {
    my ( $Sfh, $Scomment, $Snoprepend, $Snoipinfo ) = @_;
    push @mlogS, [ $Sfh, $Scomment, $Snoprepend, $Snoipinfo , 1];
}
