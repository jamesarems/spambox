#line 1 "sub main::BayesCharClean"
package main; sub BayesCharClean {
    my $word = shift;
    $$word =~ s/#(?:[a-f0-9]{2})+/randcolor/go;
    $$word =~ s/^#\d+/randdecnum/go;
    $$word =~ s/(?:[a-f0-9]{2}){3,}/randword/go;
    $$word =~ s/[\d,.]{2,}/randnumber/go;
    $$word =~ s/[_\[\]\~\@\%\$\&\{\}<>#(),.'";:=!?*+\/\\\-]+$//o;
    $$word =~ s/^[_\[\]\~\@\%\$\&\{\}<>#(),.'";:=!?*+\/\\\-]+//o;
    $$word =~ s/!!!+/!!/go;
    $$word =~ s/\*\*+/**/go;
    $$word =~ s/--+/-/go;
    $$word =~ s/__+/_/go;
    $$word =~ s/^[\d:\.\-+();<>,!"'\/%]+(?:[ap]m)?$/randwildnum/o;    # ignore numbers , dates, times, versions ...
    $$word =~ s/['"]/quote/go;
}
