#line 1 "sub main::exportOptRE"
package main; sub exportOptRE {
    my ($ree, $name ) = @_;
    return unless $WorkerNumber == 0;
    my $re = $$ree;
    $name =~ s/[\^\s\<\>\?\"\'\:\|\\\/\*\&\.]/_/igo;  # remove not allowed characters from file name
    $name =~ s/\_+/_/go;
    return if (! $re || ! $name);
    -d "$base/files/optRE" or mkdir "$base/files/optRE", 0755;
    my $optRE;
    if (open $optRE, '>',"$base/files/optRE/$name.txt") {
        binmode $optRE;
        if (exists $cryptConfigVars{$name}) {
            print $optRE SPAMBOX::CRYPT->new($webAdminPassword,0)->ENCRYPT($re);
            $CryptFile{"$base/files/optRE/$name.txt"} = 1;
        } else {
            print $optRE $re;
        }
        $availOptRE{$name} = 1 if close $optRE;
    } else {
        mlog(0,"error: unable to open $base/files/optRE/$name.txt for writing - $!");
        delete $availOptRE{$name};
    }
    return;
}
