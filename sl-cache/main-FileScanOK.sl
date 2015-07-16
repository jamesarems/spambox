#line 1 "sub main::FileScanOK"
package main; sub FileScanOK {
    my ($fh,$bd)=@_;
    return 1 unless $FileScanCMD;
    return 1 if ($fh !~ /^\d+$/o && ! haveToFileScan($fh));
    return FileScanOK_Run($fh,$bd);
}
