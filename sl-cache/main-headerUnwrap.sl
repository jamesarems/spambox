#line 1 "sub main::headerUnwrap"
package main; sub headerUnwrap {
    $_[0]=~s/\015\012[ \t]//go;
}
