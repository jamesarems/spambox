#line 1 "sub main::ConfigChangeUSAMN"
package main; sub ConfigChangeUSAMN {
    my ($name, $old, $new, $init)=@_;
    return if $WorkerNumber != 0;
    mlog(0,"AdminUpdate: $name from '$old' to '$new'") unless $init || $new eq $old;
    $Config{$name} = $new;
    $$name = $new;
    &ConfigChangeMaxAllowedDups('MaxAllowedDups',$MaxAllowedDups,$MaxAllowedDups,'');
}
