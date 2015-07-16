#line 1 "sub main::headerSmartUnwrap"
package main; sub headerSmartUnwrap {
    $_[0]=~s/\015\012[ \t]+/ /go;
}
