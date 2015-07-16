#line 1 "sub main::push_ChangeConfigVar"
package main; sub push_ChangeConfigVar {
    threads->yield;
    lock(@changedConfig);
    threads->yield;
    push @changedConfig , @_;
    threads->yield;
}
