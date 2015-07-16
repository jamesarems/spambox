#line 1 "sub main::ConfigSuspendResume"
package main; sub ConfigSuspendResume {
    $allIdle -= 2 if $allIdle == defined *{'yield'};
    $allIdle += defined *{'yield'} if $allIdle == 0;
}
