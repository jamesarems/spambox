#line 1 "sub main::mlogWrite"
package main; sub mlogWrite {
    return if $WorkerNumber;
    my @m;
    my $items;
    threads->yield();
    &debugWrite();
    threads->yield;
    $items = $mlogQueue->pending();
    $refreshWait = (time - $lastmlogWrite) > 5 ? 5 : 1;
    return if (! $items);
    threads->yield();
    @m = $mlogQueue->dequeue_nb($items);
    threads->yield();
    my @tosyslog;
    while (@m) {
       my $logline = my $line = de8(shift @m);
       if ($CanUseTextUnidecode && $Unidecode2Console) {
           eval{
               $line = eval{Text::Unidecode::unidecode(d8($line));};
           } or print "con uni-decoding error: $@";
       } else {
           eval{
               Encode::from_to($line,'UTF-8',$ConsoleCharset,sub { return '?'; })
                   if $ConsoleCharset && $ConsoleCharset !~ /utf-?8/oi;
               1;
           } or print "con encoding error: $@";
       }
       push @tosyslog,substr($line,length($LogDateFormat)) if ($sysLog && ($CanUseSyslog || ($sysLogPort && $sysLogIp)));
       if ($line !~ /\*\*\*spambox\&is\%alive\$\$\$/o) {
           print $line unless ($silent);
           w32dbg($line) if ($CanUseWin32Debug);
           if ($logfile && $spamboxLog && fileno($LOG)) {
               my $skipPrint;
               my $ll = substr($logline,length($LogDateFormat));
               $ll =~ s/^.*?\[Worker_\d+\]\s*//o;
               if ($ll =~ /^(?:info|warning|error)\s*:/oi) {
                   my ($type) = $lastPrintLine =~ /^(info|warning|error)\s*:/oi;
                   if ($lastPrintLine eq $ll && $lastPrintTime < (time - 120) ) {
                       $lastPrintCount++;
                       $lastPrintLine =~ s/[\r\n]+$//o;
                       print $LOG $lastPrintLine . " (suppressed $lastPrintCount concurrent equal '$type' loglines from all Workers in the last ".(time - $lastPrintTime)." seconds)\n";
                       $lastPrintLine = $ll;
                       $lastPrintCount = 1;
                       $lastPrintTime = time;
                   } elsif ($lastPrintLine eq $ll) {
                       $lastPrintCount++;
                       $skipPrint = 1;
                   } elsif ($lastPrintCount > 1) {
                       $lastPrintLine =~ s/[\r\n]+$//o;
                       print $LOG $lastPrintLine . " (suppressed $lastPrintCount concurrent equal '$type' loglines from all Workers)\n";
                       $lastPrintLine = $ll;
                       $lastPrintCount = 1;
                       $lastPrintTime = time;
                   } else {
                       $lastPrintLine = $ll;
                       $lastPrintCount = 1;
                       $lastPrintTime = time;
                   }
               }
               print $LOG $logline if (! $skipPrint);
           }
           print $LOGBR $logline if ($logfile &&
                                     $spamboxLog &&
                                     fileno($LOGBR) &&
                                     $ExtraBlockReportLog &&
                                     $logline =~ /\[\s*spam\sfound\s*\]/io);
       }
       if ($logline !~ /page:\/maillog|\*\*\*spambox\&is\%alive\$\$\$/o) {
           shift @RealTimeLog if (@RealTimeLog > 33);
           push @RealTimeLog, $logline;
           $lastmlogWrite = time;
       }
    }
    tosyslog('info', \@tosyslog) if (@tosyslog && $sysLog && ($CanUseSyslog || ($sysLogPort && $sysLogIp)));
    $MainThreadLoopWait = 1;
}
