#line 1 "sub main::ThreadMonitorMainLoop"
package main; sub ThreadMonitorMainLoop {
     my $t = shift;
     return if $WorkerNumber;
     return unless $MonitorMainThread;
     threads->yield();
     $MainLoopStepTime = time;
     threads->yield();
     $MainLoopLastStep = $t;
     threads->yield();
}
