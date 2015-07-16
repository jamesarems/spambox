#line 1 "sub main::configUpdateRWL"
package main; sub configUpdateRWL {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: RWL-Enable updated from '$old' to '$new'") unless $init || $new eq $old;
    $ValidateRWL=$Config{ValidateRWL}=$new unless $WorkerNumber;
    unless ($CanUseRWL) {
        mlog(0,"AdminUpdate:error RWL-Enable updated from '1' to '', Net::DNS not installed") if $Config{ValidateRWL};
        ($ValidateRWL,$Config{ValidateRWL})=();
        return '<span class="negative">*** Net::DNS must be installed before enabling RWL.</span>';
    } else {
        configUpdateRWLMH('RWLminhits','',$Config{RWLminhits},'Cascading');
    }
}
