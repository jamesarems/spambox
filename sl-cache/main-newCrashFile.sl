#line 1 "sub main::newCrashFile"
package main; sub newCrashFile {
    my $fh = shift;
    if (! $Con{$fh}->{relayok} && $enableCrashAnalyzer) {
        my $ip = $Con{$fh}->{ip};
        my $fn = "$base/crash_repo/cr_0_" . Time::HiRes::time().".w$WorkerNumber.txt";
        $Con{$fh}->{crashfn} = $fn;
        open(my $crashfh,'>',$fn);
        binmode($crashfh);
        $crashfh->autoflush;
        $Con{$fh}->{crashfh} = $crashfh;
        print $crashfh "+-+***+!+time:  ".timestring() .' / '. Time::HiRes::time()."+-+***+!+\r\n";
        print $crashfh "+-+***+!+connected IP:  $ip+-+***+!+\r\n";
        $Con{$fh}->{crashbuf} = "connected IP:  $ip\r\n";
        return 1;
    }
    return 0;
}
