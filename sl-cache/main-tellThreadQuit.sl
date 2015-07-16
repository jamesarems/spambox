#line 1 "sub main::tellThreadQuit"
package main; sub tellThreadQuit {
    my $thread = shift;
    mlog(0,"tell Worker $thread - QUIT") if ($WorkerLog);
    $ComWorker{$thread}->{run} = 0;
    ThreadYield;
    $ThreadQueue{$thread}->enqueue("run") if ($ComWorker{$thread}->{issleep});
    ThreadYield;
}
