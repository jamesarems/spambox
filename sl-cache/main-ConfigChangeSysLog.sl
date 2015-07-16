#line 1 "sub main::ConfigChangeSysLog"
package main; sub ConfigChangeSysLog {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: $name changed to '$new' from '$old'") unless ($init || $new eq $old);

    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    undef $SysLogObj;
    return '';
}
