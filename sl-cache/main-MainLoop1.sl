#line 1 "sub main::MainLoop1"
package main; sub MainLoop1 {
    my $wait = shift;
    return 0 if ($shuttingDown);
    my $AWS = $ActWebSess;
    my %QS = %qs;
    $wait = &MainLoop($wait);
    $ActWebSess = $AWS;
    %qs = %QS;
    return $wait;
}
