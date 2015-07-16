#line 1 "sub main::unloadSub"
package main; sub unloadSub {
    my $sub = shift;
    $sub = 'main::'.$sub unless $sub =~ /::/;
    if (defined &{$sub}) {
        d("Worker $WorkerNumber undefines sub $sub");
        undef &{$sub};
    }
    $CanUseAsspSelfLoader && delete $AsspSelfLoader::Cache{$sub};
    $sub .= '_Run';
    if (defined &{$sub}) {
        d("Worker $WorkerNumber undefines sub $sub");
        undef &{$sub};
    }
    $CanUseAsspSelfLoader && delete $AsspSelfLoader::Cache{$sub};
}
