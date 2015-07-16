#line 1 "sub main::downloadDropList"
package main; sub downloadDropList {
    d('droplistdownload-start');
    my $ret;
    my ($file) = $droplist =~ /^ *file: *(.+)/io;
    $ret = downloadHTTP("http://www.spamhaus.org/drop/drop.lasso",
                 "$base/$file.tmp",
                 \$NextDroplistDownload,
                 "Droplist",5,9,2,1) if $file;
    if ($ret) {
        open (my $F, '<' , "$base/$file.tmp") or return;
        my $firstline = <$F>;
        close $F;
        if ($firstline =~ /^\s*;\s*Spamhaus\s+DROP\s+List/io ) {
            unlink "$base/$file";
            copy("$base/$file.tmp","$base/$file");
        } else {
            mlog(0,"warning: the file $droplist was downloaded but contains no usable data - ignoring the download");
            return;
        }
        $ConfigChanged = 1;         # tell all to reload Config
    }
    return $ret;
}
