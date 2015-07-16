#line 1 "sub main::configChangeRT"
package main; sub configChangeRT {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: SMTP Destination Routing Table updated from '$old' to '$new'") unless $init || $new eq $old;
    $Config{smtpDestinationRT} = $smtpDestinationRT = $new unless $WorkerNumber;
    $new = checkOptionList($new,'smtpDestinationRT',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $error;
    my %tcrtable;
    my $countOK;
    my $count;
    my $re = '\s*('.$HostRe.')\s*=>\s*('.$HostPortRe.')';
    for my $v (split(/\|/o,$new)) {
        $count++;
        if ($v=~/$re/o) {
            $tcrtable{$1} = $2;
            $countOK++;
        } else {
            mlog(0,"error: smtpDestinationRT - entry $v is wrong and is ignored") if $WorkerNumber == 0;
            $error .= "<br />entry $v is wrong and is ignored";
        }
    }
    mlog(0,"info: registered $countOK entries from $count defined for SMTP Destination Routing Table") if $count && $init && $WorkerNumber == 0 && $MaintenanceLog >=2;
    %crtable = %tcrtable;
    return $error;
}
