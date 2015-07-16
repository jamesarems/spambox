#line 1 "sub main::ConfigChangePOP3File"
package main; sub ConfigChangePOP3File {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: POP3 config file updated from '$old' to '$new'") unless ($init || $new eq $old);

    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    if ($new ne $old or $init) {
        $old =~ s/^ *file: *//io;
        $new =~ s/^ *file: *//io;
        if ($old) {
            $old =~ s/\\/\//go;
            $old = "$base/$old" ;
            delete $CryptFile{$old};
            mlog(0,"info: deregistered encrypted $name file $old") if $WorkerNumber == 0 && $new ne $old;
        }
        if ($new) {
            $new =~ s/\\/\//go;
            $new = "$base/$new" ;
            $CryptFile{$new} = 1;
            mlog(0,"info: registered encrypted $name file $new") if $WorkerNumber == 0;
        }
    }
    return '';
}
