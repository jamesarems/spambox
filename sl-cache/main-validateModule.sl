#line 1 "sub main::validateModule"
package main; sub validateModule {
    my $module = shift;
    $module =~ s/^\s*use\s+//o;
    my $var; my $k;
    ($module, $var) = split(/\s+/o,$module,2);
    ($module, $k) = ($1,$2) if $module =~ /^([^\s()]+)(\(\))?$/o;
    delete $ModuleError{$module};
    $k = '()' if (! $k && ! $var && $module !~ s/\+$//o);
    return 1 if (eval("use $module$k $var;1;"));
    $ModuleError{$module} = $@;
    return 0;
}
