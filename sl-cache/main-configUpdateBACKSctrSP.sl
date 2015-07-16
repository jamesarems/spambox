#line 1 "sub main::configUpdateBACKSctrSP"
package main; sub configUpdateBACKSctrSP {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: Backscatter Service Providers updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new = checkOptionList($new,'BackSctrServiceProvider',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    @backsctrlist=split(/\s*\|\s*/o,$new);
    if (@backsctrlist && $DoBackSctr) {
        return ' & Backscatterer check is activated';
    } else {
        return ' Backscatterer check is deactivated';
    }
}
