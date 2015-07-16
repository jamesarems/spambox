#line 1 "sub main::updateSRS"
package main; sub updateSRS {my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: SRS-Enable updated from '$old' to '$new'") unless $init || $new eq $old;
    $EnableSRS=$Config{EnableSRS}=$new unless $WorkerNumber;
    if (!$CanUseSRS) {
        mlog(0,"AdminUpdate: SRS-Enable updated from '1' to '', Mail::SRS not installed") if $Config{EnableSRS};
        $EnableSRS=$Config{EnableSRS}=undef;
        return '<span class="negative">*** Mail::SRS must be installed before enabling SRS.</span>';
    } else {
        updateSRSAD('updateSRSAD','',$Config{SRSAliasDomain},'Cascading');
    }
}
