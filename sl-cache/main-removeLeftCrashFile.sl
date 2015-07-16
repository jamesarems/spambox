#line 1 "sub main::removeLeftCrashFile"
package main; sub removeLeftCrashFile {
    foreach (keys %CrFn2Remove) {
        unlink($_);
        delete $CrFn2Remove{$_} if ! -e "$_";
    }
    return 1;
}
