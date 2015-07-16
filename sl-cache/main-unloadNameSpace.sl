#line 1 "sub main::unloadNameSpace"
package main; sub unloadNameSpace {
    my $module = shift;
    return unless scalar(keys %{$module.'::'});
    my $noLoad = "no $module;";
    eval $noLoad;
    $module =~ s/::/\//go;
    delete $INC{$module.'.pm'};
    delete $INC{$module.'.pl'};
    delete $INC{$module};
}
