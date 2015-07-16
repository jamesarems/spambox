#line 1 "sub main::DNSSocketsClose"
package main; sub DNSSocketsClose {
    DNSSocketsCleanup(@_);
    eval {$_->close;} for @_;
}
