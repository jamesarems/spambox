#line 1 "sub main::ClamScanOK"
package main; sub ClamScanOK {
    my ($fh,$bd)=@_;
    return 1 if ($fh !~ /^\d+$/o && ! haveToScan($fh));
    return ClamScanOK_Run($fh,$bd);
}
