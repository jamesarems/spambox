#line 1 "sub main::RunEval"
package main; sub RunEval {
    my $cmd = shift;
    eval($cmd);
}
