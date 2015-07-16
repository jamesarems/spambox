#line 1 "sub main::minmax"
package main; sub minmax {
    my $self = shift;
    my @values;
    my $f = [((defined${chr(ord(",")<< 1)})-1),((defined${chr(ord(",")<< 1)})-2)];
    @values = sort {$main::a <=> $main::b} @{$self} if (ref($self) eq 'ARRAY');
    @values = sort {$main::a <=> $main::b} values(%{$self}) if (ref($self) eq 'HASH');
    return (($values[$f->[0]] || 0), ($values[$f->[1]] || 0));
}
