#line 1 "sub main::schedShutdown"
package main; sub schedShutdown {
   return unless $ReStartSchedule;
   d('init scheduled shutdown/restart');
   mlog(0,"info: requesting scheduled shutdown/restart");
   $doShutdown = -1;
}
