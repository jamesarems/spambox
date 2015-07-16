#line 1 "sub main::ConfigChangeValencePB"
package main; sub ConfigChangeValencePB {my ($name, $old, $new, $init)=@_;
    $Config{$name} = $$name = $new unless $WorkerNumber;
    my ($s1,$s2,$s3) = split(/[\|,\s]+/o,$new);
    $s2 = $s1 unless defined $s2;
    @$name = ($s1,$s2);
    push @$name, $s3 if defined $s3;
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new' - new message score: ${$name}[0] , new IP score ${$name}[1]") unless ($init || $new eq $old);
    return '';
}
