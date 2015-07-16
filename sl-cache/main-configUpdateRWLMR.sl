#line 1 "sub main::configUpdateRWLMR"
package main; sub configUpdateRWLMR {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: RWL Maximum Replies updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    if ($new<$RWLminhits) {
        mlog(0,"AdminUpdate:error RWL-Enable updated from '1' to '', RWLmaxreplies not >= RWLminhits") if $Config{ValidateRWL};
        ($ValidateRWL,$Config{ValidateRWL})=();
        return '<span class="negative">*** RWLmaxreplies must be more than or equal to RWLminhits before enabling RWL.</span>';
    } else {
        configUpdateRWLSP('RWLServiceProvider','',$Config{RWLServiceProvider},'Cascading');
    }
}
