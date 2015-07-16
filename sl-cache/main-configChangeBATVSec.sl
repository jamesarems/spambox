#line 1 "sub main::configChangeBATVSec"
package main; sub configChangeBATVSec {
    my ($name, $old, $new, $init)=@_;

    mlog(0,"AdminUpdate: BATV secrets updated from '$old' to '$new'") unless $init || $new eq $old;
    $BATVSec=$new unless $WorkerNumber;
    $new = checkOptionList($new,'BATVSec',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    @batv_secrets = ();
    my @errors;
    my $errout;
    my $count = -1;
    my $records = -1;
    for my $v (split(/\|/o,$new)) {
        push @errors, $v;
        $records++;
        next unless $v;
        next if ($v =~ /\s+/igo);
        my ($gen,$sec) = split(/=/o,$v);
        next unless ($gen ne '' && $sec);
        next unless ($gen =~ /^\d$/o);
        pop @errors;
        $count++;
        last if ($count == 10);
        $batv_secrets[$count]{gen} = $gen;
        $batv_secrets[$count]{secret} = $sec;
    }
    $errout = join('|',@errors);
    if ($count == -1) {
        $records++;
        $count++;
        my $diff = $records -$count;
        my $ignored = $diff ? " : $diff records ignored because of wrong syntax : $errout" : '';
        mlog(0, "warning: NO BATV-secrets activated - BATV-check is now disabled $ignored")  if (! $calledfromThread);
        return "<span class=\"negative\"> - NO BATV-secrets activated - BATV-check is now disabled $ignored</span>";
    } else {
        $records++;
        $count++;
        my $diff = $records -$count;
        my $ignored = $diff ? " : $diff records ignored because of wrong syntax : $errout" : '';
        mlog(0, "info: $count BATV-secrets activated") if (! $calledfromThread);
        return $diff ? " $count BATV-secrets activated <span class=\"negative\"> - $ignored</span>" : " $count BATV-secrets activated";
    }
}
