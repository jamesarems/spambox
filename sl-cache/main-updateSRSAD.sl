#line 1 "sub main::updateSRSAD"
package main; sub updateSRSAD {my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: SRS Alias Domain updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    if ($new eq '') {
        mlog(0,"AdminUpdate: SRS-Enable updated from '1' to '', SRSAliasDomain not defined ") if $Config{EnableSRS};
        $EnableSRS=$Config{EnableSRS}=undef;
        return '<span class="negative">*** SRSAliasDomain must be defined before enabling SRS.</span>';
    } else {
        updateSRSSK('updateSRSSK','',$Config{SRSSecretKey},'Cascading');
    }
}
