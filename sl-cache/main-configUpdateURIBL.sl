#line 1 "sub main::configUpdateURIBL"
package main; sub configUpdateURIBL {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: URIBL-Enable updated from '$old' to '$new'") unless $init || $new eq $old;

    $ValidateURIBL=$Config{ValidateURIBL}=$new unless $WorkerNumber;
    unless ($CanUseURIBL) {
        mlog(0,"AdminUpdate:error URIBL-Enable updated from '1' to '', Net::DNS not installed") if $Config{ValidateURIBL};
        ($ValidateURIBL,$Config{ValidateURIBL})=();
        return '<span class="negative">*** Net::DNS must be installed before enabling URIBL.</span>';
    } else {
        configUpdateURIBLMH('URIBLmaxhits','',$Config{URIBLmaxhits},'Cascading');
    }
}
