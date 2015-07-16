#line 1 "sub main::configUpdateRWLSP"
package main; sub configUpdateRWLSP {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: RWL Service Providers updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new = checkOptionList($new,'RWLServiceProvider',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $domains=($new=~s/\|/|/go)+1;
    if ($domains<$RWLmaxreplies) {
        mlog(0,"AdminUpdate:error RWL-Enable updated from '1' to '',RWLServiceProvider not >= RWLmaxreplies ") if $Config{ValidateRWL};
        ($ValidateRWL,$Config{ValidateRWL})=();
        return '<span class="negative">*** RWLServiceProvider must contain more than or equal to RWLmaxreplies  before enabling RWL.</span>';
    } elsif ($CanUseRWL) {

        @rwllist=split(/\|/o,$new);
        if (@rwllist && $ValidateRWL) {
            return ' & RWL activated';
        } else {
            return 'RWL deactivated';
        }
    }
}
