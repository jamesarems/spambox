#line 1 "sub main::initGlobalThreadVar"
package main; sub initGlobalThreadVar {
    &setMakeREVars();
    &ThreadCompileAllRE(1) if $calledfromThread;
    undef $readable;
    undef $writable;
    %SocketCalls = ();
    %SocketCallsNewCon = ();
    %Con = ();
    %ConDelete = ();
    if ($IOEngineRun == 0) {
        $readable = IO::Poll->new();
        $writable = IO::Poll->new();
    } else {
        $readable = IO::Select->new();
        $writable = IO::Select->new();
    }
}
