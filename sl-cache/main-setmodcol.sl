#line 1 "sub main::setmodcol"
package main; sub setmodcol {
    my $modname = shift;
    my $mod = $modname;
    $mod =~ s/:://go;
    my $modvar = 'use'.$mod;
    if ($$modvar) {
        return ">$modname</a>";
    } else {
        return "><span class=\"negative\">$modname</span></a>";
    }
}
