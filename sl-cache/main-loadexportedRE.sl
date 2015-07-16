#line 1 "sub main::loadexportedRE"
package main; sub loadexportedRE {
    my $name = shift;
    return 0 if $WorkerNumber == 0;
    $name =~ s/[\^\s\<\>\?\"\'\:\|\\\/\*\&\.]/_/igo;  # remove not allowed characters from file name
    $name =~ s/\_+/_/go;
    return 0 if (! $name);
    return 0 unless exists $availOptRE{$name};
    (open my $optRE, '<',"$base/files/optRE/$name.txt") or return 0;
    binmode $optRE;
    my $re = join('',<$optRE>);
    close $optRE;
    if (exists $CryptFile{"$base/files/optRE/$name.txt"} && $re =~ /^(?:[a-zA-Z0-9]{2})+$/o) {
        $re = SPAMBOX::CRYPT->new($webAdminPassword,0)->DECRYPT($re);
    }
    return $re;
}
