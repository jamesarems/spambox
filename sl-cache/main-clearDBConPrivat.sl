#line 1 "sub main::clearDBConPrivat"
package main; sub clearDBConPrivat {
    eval {
        undef $GriplistObj;
        untie %Griplist;
    };
    return if $WorkerNumber == 10001; # rebuildspamdb tied only the Griplist
    foreach (keys %tempDBvars) {
        eval {
        undef ${$_ .'Obj'};
        untie(%{$_});
        };
    }
}
