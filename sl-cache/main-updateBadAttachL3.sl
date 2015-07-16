#line 1 "sub main::updateBadAttachL3"
package main; sub updateBadAttachL3 {my ($name, $old, $new, $init)=@_;
    mlog(0,"Badattach Level 3 updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new.='|' if $new;
    $new.=$init;
    SetRE('badattachL3RE',qq[\\.(?:$new)\$],
          $regexMod,
          'bad attachment L3',$name);
    $badattachRE[1]=$badattachL1RE;
    $badattachRE[2]=$badattachL2RE;
    $badattachRE[3]=$badattachL3RE;
    return ConfigShowError(1,$RegexError{$name});
}
