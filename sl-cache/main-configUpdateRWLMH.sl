#line 1 "sub main::configUpdateRWLMH"
package main; sub configUpdateRWLMH {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: RWL Minimum Hits updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    if ($new<=0) {
        mlog(0,"AdminUpdate:error RWL-Enable updated from '1' to '', RWLminhits must be defined and positive") if $Config{ValidateRWL};
        ($ValidateRWL,$Config{ValidateRWL})=();
        return '<span class="negative">*** RWLminhits must be defined and positive before enabling RWL.</span>';
    } else {
        configUpdateRWLMR('RWLmaxreplies','',$Config{RWLmaxreplies},'Cascading');
    }
}
