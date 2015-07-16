#line 1 "sub main::debugWrite"
package main; sub debugWrite {
    my @m;
    my $items = $debugQueue->pending();
    if ((! $debugIP && ! $debugRe && ! $debugCode && ! $debug && $DEBUG && $DEBUG->opened) or ($lastDebugPrint && time - $lastDebugPrint > 600)) {
        mlog(0,'info: partial debug mode stopped');
        eval{$lastDebugPrint = 0; $DEBUG->close; undef $DEBUG;};
    }
    return if (! $items);
    if (! $DEBUG || ! $DEBUG->opened) {
        my $file = "$base/debug/".time.".dbg";
        open($DEBUG, '>',"$file");
        binmode($DEBUG);
        $DEBUG->autoflush;
        print $DEBUG $UTF8BOM;
        print $DEBUG "running ASSP version: $main::MAINVERSION\n\n";
        mlog(0,"info: starting partial debug mode to file $file");
    }
    threads->yield();
    @m = $debugQueue->dequeue_nb($items);
    threads->yield();
    while (@m && $DEBUG) {
       print $DEBUG shift @m;
    }
    $lastDebugPrint = time unless ($debug);
}
