#line 1 "sub main::ThreadChangeVar"
package main; sub ThreadChangeVar {
    my ($var,$parm) = @_;
    $$var = $parm;
}
