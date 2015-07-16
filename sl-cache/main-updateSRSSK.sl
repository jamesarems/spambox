#line 1 "sub main::updateSRSSK"
package main; sub updateSRSSK {my ($name, $old, $new, $init)=@_;
    mlog( 0, "AdminUpdate: SRS Secret Key updated from '$old' to '$new'" ) unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    if (length($new)<5) {
        mlog(0,"AdminUpdate: SRS-Enable updated from '1' to '', SRSSecretKey not at least 5 characters long ") if $Config{EnableSRS};
        $EnableSRS=$Config{EnableSRS}=undef;
        return '<span class="negative">*** SRSSecretKey must be at least 5 characters long before enabling SRS.</span>';
    } elsif($CanUseSRS) {
        if ($init && $EnableSRS) {
            return ' & SRS activated';
        } else {
            return '';
        }
    }
}
