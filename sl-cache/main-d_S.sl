#line 1 "sub main::d_S"
package main; sub d_S {
 my ($Sdebugprint,$Snostep) = @_;
 $lastd{$WorkerNumber} = $Sdebugprint unless $Snostep;
 threads->yield();
 return unless ($debug || $ThreadDebug);
 my $Stime=&timestring();
 $Sdebugprint =~ s/\n/\[LF\]\n/go;
 $Sdebugprint =~ s/\r/\[CR\]/go;
 $Sdebugprint .= "\n" if $Sdebugprint !~ /\n$/o;
 threads->yield();
 $debugQueue->enqueue("$Stime [$WorkerName] <$Sdebugprint>");
 threads->yield();
}
