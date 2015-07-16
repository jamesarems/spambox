#line 1 "sub main::downloadTLDList"
package main; sub downloadTLDList {
    d('TLDlistdownload-start');
    my $ret;
    my $ret2;
    my $ret3;
    my $n1;
    my $n2;
    my $n3;
    $NextTLDlistDownload = time + 7200;

    my ($file) = $TLDS =~ /^ *file: *(.+)/io;
    $ret = downloadHTTP(
                 $tlds_alpha_URL,
                 "$base/$file",
                 \$n1,
                 "TLDlist",24,48,2,1) if $file;

    ($file) = $URIBLCCTLDS =~ /^ *file: *(.+)/io;
    $ret2 = downloadHTTP(
                 $tlds2_URL,
                 "$base/files/URIBLCCTLDS-L2.txt",
                 \$n2,
                 "level-2-TLDlist",24,48,2,1) if $file;
    $ret3 = downloadHTTP(
                 $tlds3_URL,
                 "$base/files/URIBLCCTLDS-L3.txt",
                 \$n3,
                 "level-3-TLDlist",24,48,2,1) if $file;

    if (! $file) {
        if ($n1) {
            $NextTLDlistDownload = $n1;
            return $ret;
        }
    }
    
    $NextTLDlistDownload  =  ($n1 && $n1 < $n2) ? $n1 : ($n2 > 0) ? $n2 : $NextTLDlistDownload;
    $NextTLDlistDownload  =  $n3 if $n3 &&  $NextTLDlistDownload > $n3;

    if ($file &&
        -s "$base/files/URIBLCCTLDS-L2.txt" > 0 &&
        -s "$base/files/URIBLCCTLDS-L3.txt" > 0 &&
        ($ret2 || $ret3 || ! -e "$base/$file" || -s "$base/$file" == 0))
    {
        if (((open my $f1 ,'<' ,"$base/files/URIBLCCTLDS-L2.txt") || mlog(0,"error: unable to open $base/files/URIBLCCTLDS-L2.txt")&0) &&
            ((open my $f2 ,'<' ,"$base/files/URIBLCCTLDS-L3.txt") || mlog(0,"error: unable to open $base/files/URIBLCCTLDS-L3.txt")&0) &&
            ((open my $f3 ,'>' ,"$base/$file") || mlog(0,"error: unable to open $base/$file")&0))
        {
            binmode $f3;
            print $f3 "# three level TLDs\n\n";
            while (<$f2>) {
                s/\r*\n//o;
                next unless $_;
                print $f3 "$_\n";
            }
            mlog(0,"info: merged file $base/files/URIBLCCTLDS-L3.txt in to $base/$file for URIBLCCTLDS") if $MaintenanceLog >= 2;
            print $f3 "\n\n";
            print $f3 "# two level TLDs\n\n";
            while (<$f1>) {
                s/\r*\n//o;
                next unless $_;
                print $f3 "$_\n";
            }
            mlog(0,"info: merged file $base/files/URIBLCCTLDS-L2.txt in to $base/$file for URIBLCCTLDS") if $MaintenanceLog >= 2;
            close $f3;
            close $f2;
            close $f1;
            mlog(0,"info: file $base/$file updated for URIBLCCTLDS") if $MaintenanceLog;
            $ret2 = 1;
        } else {
            mlog(0,"error: unable to read or write one of the URIBLCCTLDS files - $!");
        }
    }

    $ConfigChanged = 1 if $ret || $ret2 || $ret3;         # tell all to reload Config
    return $ret || $ret2 || $ret3;
}
