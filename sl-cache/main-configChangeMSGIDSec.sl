#line 1 "sub main::configChangeMSGIDSec"
package main; sub configChangeMSGIDSec {
    my ($name, $old, $new, $init)=@_;

    mlog(0,"AdminUpdate: MSGID secrets updated from '$old' to '$new'") unless $init || $new eq $old;
    $MSGIDSec=$new unless $WorkerNumber;
    $new = checkOptionList($new,'MSGIDSec',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    @msgid_secrets = ();
    my @errors;
    my $errout;
    my $count = -1;
    my $records = -1;
    for my $v (split(/\|/o,$new)) {
        push @errors, $v;
        $records++;
        next unless $v;
        next if ($v =~ /key\d/o) ;
        next if ($v =~ /\s+/igo);
        my ($gen,$sec) = split(/=/o,$v);
        next unless ($gen ne '' && $sec);
        next unless ($gen =~ /^\d$/o);
        pop @errors;
        $count++;
        last if ($count == 10);
        $msgid_secrets[$count]{gen} = $gen;
        $msgid_secrets[$count]{secret} = $sec;
    }
    $errout = join('|',@errors);
    if ($count == -1) {
        $records++;
        $count++;
        my $diff = $records -$count;
        my $ignored = $diff ? " : $diff records ignored because of wrong syntax or using default values : $errout" : '';
        mlog(0, "warning: NO MSGIDsig-secrets activated - MSGIDsig-check is now disabled $ignored")  if (! $calledfromThread);
        return "<span class=\"negative\"> - NO MSGID-secrets activated - MSGIDsig-check is now disabled $ignored</span>";
    } else {
        $records++;
        $count++;
        my $diff = $records -$count;
        my $ignored = $diff ? " : $diff records ignored because of wrong syntax : $errout" : '';
        mlog(0, "info: $count MSGID-secrets activated") if (! $calledfromThread);
        return $diff ? " $count MSGIDsig-secrets activated <span class=\"negative\"> - $ignored</span>" : " $count MSGIDsig-secrets activated";
    }
}
