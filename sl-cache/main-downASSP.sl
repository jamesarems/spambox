#line 1 "sub main::downASSP"
package main; sub downASSP {
    my $text = shift;
    return if $doShutdownForce;
    $doShutdownForce = 1;
    $SIG{TERM} = \&EXITASSP;
    foreach (keys %SIG) {
       next if /TERM/io;
       $SIG{$_} = 'IGNORE';
    }
    my $sequenceOK = 1;
    mlog(0,'initializing shutdown sequence');
    mlogWrite();
    $WorkerName = 'Shutdown';
    $sequenceOK &&= &closeAllSMTPListeners;
    mlogWrite();
    $sequenceOK &&= &stopSMTPThreads;
    mlogWrite();
    $sequenceOK &&= &stopHighThreads;
    mlogWrite();
    $sequenceOK && &SaveWhitelist;
    mlogWrite();
    $sequenceOK && &SavePB;
    mlogWrite();
    $sequenceOK && &SaveStats;
    mlogWrite();
    &saveRemoteSupport;
#    mlogWrite();
#    &BDB_sync(1);
    mlog(0,'closing all databases');
    mlogWrite();
    checkDBCon(0);
    mlogWrite();
    &clearDBCon();
    mlogWrite();
    &closeAllWEBListeners;
    mlogWrite();
    &syncWriteConfig() if $enableCFGShare;
    &removeLeftCrashFile();
    mlog(0,'info: shutdown reason was: '.$text) if $text;
    mlog(0,'info: shutdown - got no reason ?') if ! $text;
    mlog(0,'SPAMBOX finished work');
    &RemovePid;
    mlogWrite();
    &printVars();
}
