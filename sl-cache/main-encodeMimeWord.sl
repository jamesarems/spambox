#line 1 "sub main::encodeMimeWord"
package main; sub encodeMimeWord {
    my $word = shift;
    return '' unless $word;
    my $encoding = uc(shift || 'Q');
    my $charset  = uc(shift || 'UTF-8');
    my $encfunc  = (($encoding eq 'Q') ? \&spambox_encode_Q : \&spambox_encode_B);
    my $encword = &$encfunc($word);
    if ($word && ! $encword && $encoding eq 'Q') {
        $encword = &spambox_encode_B($word);
        $encoding = 'B';
    }
    return "=?$charset?$encoding?" . $encword . "?=";
}
