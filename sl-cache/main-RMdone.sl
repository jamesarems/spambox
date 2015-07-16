#line 1 "sub main::RMdone"
package main; sub RMdone { my ($fh,$l)=@_;
    if($l!~/^ *[24]21/o) {
        RMabort($fh,"done Expected 221 or 421, got: $l");
    } else {
        mlog(0,"info: report successful sent to ".$Con{$fh}->{to}) if $ReportLog;
        done2($fh); # close and delete
    }
}
