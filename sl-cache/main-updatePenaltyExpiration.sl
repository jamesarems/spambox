#line 1 "sub main::updatePenaltyExpiration"
package main; sub updatePenaltyExpiration {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    cmdToThread('CleanPB','') unless $init || $new eq $old;
    return '';
}
