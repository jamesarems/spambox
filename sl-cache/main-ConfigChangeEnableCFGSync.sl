#line 1 "sub main::ConfigChangeEnableCFGSync"
package main; sub ConfigChangeEnableCFGSync {my ($name, $old, $new, $init)=@_;
    return '<span class="negative"></span>' if $WorkerNumber != 0;
    my $failed;
    if ($new) {
        unless ($isShareMaster or $isShareSlave) {
            $new = $old = '';
            $enableCFGShare = $new;
            $Config{enableCFGShare} = $new;
            $failed .= "<span class=\"negative\">any of isShareMaster or isShareSlave must be selected first</span><br />";
        }
        unless ($syncConfigFile) {
            $new = $old = '';
            $enableCFGShare = $new;
            $Config{enableCFGShare} = $new;
            $failed .= "<span class=\"negative\">syncConfigFile must be configured first</span><br />";
        }
        unless ($syncServer) {
            $new = $old = '';
            $enableCFGShare = $new;
            $Config{enableCFGShare} = $new;
            $failed .= "<span class=\"negative\">at least one default syncServer must be configured first</span><br />";
        }
        unless ($syncCFGPass) {
            $new = $old = '';
            $enableCFGShare = $new;
            $Config{enableCFGShare} = $new;
            $failed .= "<span class=\"negative\">a password in syncCFGPass must be configured first</span><br />";
        }
        return $failed if $failed;
    }
    mlog(0,"AdminUpdate: $name changed from $old to $new") if ($new ne $old && ! $init);
    %subOIDLastLoad = ();

    $enableCFGShare = $new;
    $Config{enableCFGShare} = $new;
    
    return '<span class="positive">config synchronization is now activated</span>' if $new;
    return '<span class="positive">config synchronization is now deactivated</span>';
}
