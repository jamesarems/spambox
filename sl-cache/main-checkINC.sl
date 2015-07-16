#line 1 "sub main::checkINC"
package main; sub checkINC {
    for my $p ("$base","$base/lib","$base/Plugins") {
        unshift(@INC,$_) unless(grep(/^\Q$p\E$/,@INC));
    }
}
