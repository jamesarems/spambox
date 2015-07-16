#line 1 "sub main::transliterate"
package main; sub transliterate {
    my ($text, $skipequal) = @_;
    return unless ($CanUseTextUnidecode);
    my $trans = eval{e8(Text::Unidecode::unidecode(d8($$text)));};
    return ($skipequal && $trans eq $$text) ? undef : defined(*{'yield'}) ? $trans : undef;
}
