#line 1 "sub main::updateGoodAttach"
package main; sub updateGoodAttach {my ($name, $old, $new, $init)=@_;

    mlog(0,"AdminUpdate: Goodattach Level 4 updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    SetRE('goodattachRE',qq[\\.(?:$new)\$],
          $regexMod,
          'Good Attachment',$name);
    return ConfigShowError(1,$RegexError{$name});
}
