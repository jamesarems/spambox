#line 1 "sub main::downloadBackDNS"
package main; sub downloadBackDNS {
    return 0 if !$BackDNSInterval;
    return 0 if $mysqlSlaveMode && $pbdb =~ /DB:/o && !($useDB4IntCache && $CanUseBerkeleyDB);
    d('BackDNSdownload-start');
    my $ret;
    my ($file) = $localBackDNSFile =~ /^ *file: *(.+)/io;
    $file = "$base/$file" if $file;
    my $gzfile = $file . '.gz';
    $ret = downloadHTTP($BackDNSFileURL,
                 "$gzfile",
                 \$NextBackDNSFileDownload,
                 "BackDNSFile",20,24,4,4) if $file;
    if ($ret) {
        if (! &unzipgz($gzfile,$file)) {
            $FileUpdate{"$file".'localBackDNSFile'} = ftime($file);
            return 0 ;
        }
    } else {
        $FileUpdate{"$file".'localBackDNSFile'} = ftime($file);
        return 0;
    }
    &mergeBackDNS($file);
    return 1;
}
