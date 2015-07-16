#line 1 "sub main::configUpdateCA"
package main; sub configUpdateCA {
    my ($name, $old, $new, $init)=@_;
    %calist=();
    mlog(0,"AdminUpdate: Catch All Addresses updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new = checkOptionList($new,'CatchAll',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    for my $ad (split(/\|/o,$new)) {
        $calist{$2}=$1 if($ad=~/(\S*)\@(\S*)/o);
    }
}
