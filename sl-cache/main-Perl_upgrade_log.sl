#line 1 "sub main::Perl_upgrade_log"
package main; sub Perl_upgrade_log {
    my ($module,$inst_ver,$new_ver) = @_;
    open (my $F , '>>' , "$base/notes/upgraded_Perl_Modules.log") or return;
    binmode $F;
    print $F timestring() . " $module from $inst_ver to $new_ver\n";
    close $F;
    return;
}
