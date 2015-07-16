#line 1 "sub main::downloadGripConf"
package main; sub downloadGripConf {
    d('downloadGripConf-start');
    my $ret;
    my $file = "$base/griplist.conf";
    $ret = downloadHTTP("http://downloads.sourceforge.net/project/spambox/griplist/griplist.conf",
                 $file,
                 0,
                 "griplist.conf",5,9,2,1);
    mlog(0,"info: updated GRIPLIST upload and download URL's in $file") if $ret;
    $ret = 0;
    open my $GC , '<', $file or return 0;
    binmode $GC;
    while (<$GC>) {
        s/\r|\n//o;
        if (/^\s*(gripList(?:DownUrl|UpUrl|UpHost))\s*:\s*(.+)$/) {
            ${$1} = $2;
            $ret++;
        }
    }
    close
    mlog(0,"info: loaded GRIPLIST upload and download URL's from $file") if $ret;
    mlog(0,"info: GRIPLIST config $file is possibly incomplete") if $ret < 3;
    $gripListDownUrl =~ s/\*HOST\*/$gripListUpHost/o;
    $gripListUpUrl  =~ s/\*HOST\*/$gripListUpHost/o;
    return $ret;
}
