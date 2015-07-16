#line 1 "sub main::ThreadsWakeUp"
package main; sub ThreadsWakeUp {
    while (my ($k,$v) = each %Threads) {
        next if ($k > 9999);  # only for ComWorkers
        if ($ComWorker{$k}->{run} == 1 &&
            $ComWorker{$k}->{issleep} &&
            time - $WorkerLastAct{$k} + rand(58) >= $ThreadsWakeUpInterval)
        {
            threads->yield;
            $ThreadQueue{$k}->enqueue('status');
            threads->yield;
        }
    }
}
