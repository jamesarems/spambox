#line 1 "sub main::Perl_no_upgrade"
package main; sub Perl_no_upgrade {
    open (my $F , '<' , "$base/files/noupgrade.txt") or return;
    my %modules;
    my %list;
    binmode $F;
    while (<$F>) {
        s/[\r\n\s]//go;
        s/[#;].*//o;
        next unless $_;
        $list{$_} = $modules{$_} = 1;
        s/::/-/go;
        $modules{$_} = 1;
    }
    close $F;
    foreach (keys %list) {
        mlog(0,"info: Perl auto module update will ignore module $_") if $MaintenanceLog;
    }
    return %modules;
}
