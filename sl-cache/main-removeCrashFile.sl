#line 1 "sub main::removeCrashFile"
package main; sub removeCrashFile {
    my $fh = shift;
    my $ret = 0;
    my $crashfn;
    if ($Con{$fh}->{crashfh}) {
        my $crashfh = $Con{$fh}->{crashfh};
        $crashfn = $Con{$fh}->{crashfn};
        close $crashfh;
        delete $Con{$fh}->{crashfh};
        delete $Con{$fh}->{crashfn};
        delete $Con{$fh}->{crashbuf};
        ($ret = unlink($crashfn)) or $CrFn2Remove{$crashfn} = 1;
    }
    removeLeftCrashFile();
    $ret ||= $crashfn && ! -e "$crashfn";
    return $ret;
}
