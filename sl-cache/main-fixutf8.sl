#line 1 "sub main::fixutf8"
package main; sub fixutf8 {
    if (! &is_7bit_clean($_[0]) && ! Encode::is_utf8(${$_[0]},1)) {
        mlog(0,"info: assp tries to correct possible utf8 mistakes") if $SessionLog > 1;
        Encode::_utf8_on(${$_[0]});
        my $utext = eval {Encode::decode('utf8', Encode::encode('utf8', ${$_[0]}))};
        mlog(0,"info: utf8 - $@") if $@;
        ${$_[0]} = $utext if $utext;
    }
    return;
}
