#line 1 "sub main::ConfigCheckGroupWatch"
package main; sub ConfigCheckGroupWatch {
    my $group = shift;
    foreach my $config (sort {$ConfigNum{$main::a} cmp $ConfigNum{$main::b}} keys %{$GroupWatch{$group}}) {
        eval{$GroupWatch{$group}->{$config}->[0]->($config,$Config{$config},$Config{$config},'',$GroupWatch{$group}->{$config}->[1]);};
    }
}
