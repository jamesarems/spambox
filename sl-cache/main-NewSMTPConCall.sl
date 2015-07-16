#line 1 "sub main::NewSMTPConCall"
package main; sub NewSMTPConCall {
    return unless scalar keys %SocketCallsNewCon;
    &sigoffTry(__LINE__);
    while (my ($k,$v) = each %SocketCallsNewCon) {
        $v->($k);
    }
    &sigonTry(__LINE__);
}
