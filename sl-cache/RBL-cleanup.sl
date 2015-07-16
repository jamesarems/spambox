#line 1 "sub RBL::cleanup"
package RBL; sub cleanup {
    # remove control chars and stuff
    $_[ 0 ] =~ tr/a-zA-Z0-9./ /cs;
    $_[ 0 ];
}
