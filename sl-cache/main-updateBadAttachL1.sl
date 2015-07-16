#line 1 "sub main::updateBadAttachL1"
package main; sub updateBadAttachL1 {my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: Badattach Level 1 updated from '$old' to '$new'") unless $init || $new eq $old;
    SetRE('badattachL1RE',qq[\\.(?:$new)\$],
          $regexMod,
          'bad attachment L1',$name);
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    return ConfigShowError(1,$RegexError{$name}) . updateBadAttachL2('BadAttachL2','',$Config{BadAttachL2},$new);
}
