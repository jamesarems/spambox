#line 1 "sub main::d"
package main; sub d {
 my ($debugprint,$nostep) = @_;
 $lastd{$WorkerNumber} = $debugprint unless $nostep;
 threads->yield();
 return unless ($debug || $ThreadDebug);
 my $time=&timestring();
 $debugprint =~ s/\n/\[LF\]\n/go;
 $debugprint =~ s/\r/\[CR\]/go;
 $debugprint .= "\n" if $debugprint !~ /\n$/o;
 threads->yield();
 $debugQueue->enqueue("$time [$WorkerName] <$debugprint>");
 threads->yield();
}
