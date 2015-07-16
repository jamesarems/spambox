#line 1 "sub main::updateBadAttachL2"
package main; sub updateBadAttachL2 {my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: Badattach Level 2 updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new.='|' if $new;
    $new.=$init;
    SetRE('badattachL2RE',qq[\\.(?:$new)\$],
          $regexMod,
          'bad attachment L2',$name);
    return ConfigShowError(1,$RegexError{$name}) . updateBadAttachL3('BadAttachL3','',$Config{BadAttachL3},$new);
}
