#line 1 "sub main::newThread"
package main; sub newThread {
    my $Iam = shift;
    $ComWorker{$Iam} = &share({});
    $ComWorker{$Iam}->{run} = 1;
    $ComWorker{$Iam}->{issleep} = 0;
    $ComWorker{$Iam}->{inerror} = 0;
    $ComWorker{$Iam}->{newCon} = &share({});
    $ThreadQueue{$Iam} = Thread::Queue->new();
    my $rq = "r".$Iam;
    $ThreadQueue{$rq} = Thread::Queue->new();
    if ($ThreadStackSize) {
        $Threads{$Iam} = threads->create({'stack_size' => 1024*1024*$ThreadStackSize},\&ThreadStart,$Iam,$ThreadQueue{$Iam},$ThreadQueue{$rq});
    } else {
        $Threads{$Iam} = threads->create(\&ThreadStart,$Iam,$ThreadQueue{$Iam},$ThreadQueue{$rq});
    }
}
