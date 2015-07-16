#line 1 "sub main::SMTPSessionLimitCheck"
package main; sub SMTPSessionLimitCheck {
    my $numsess;
    d('SMTPSessionLimitCheck');
    threads->yield;
    $numsess = $SMTPSessionIP{Total};
    if ($numsess <= 0) {
        threads->yield;
        $numsess = $SMTPSessionIP{Total} = 0;
        threads->yield;
    }
    my $maxSMTPSessions = $maxSMTPSessions;
    return if ! $maxSMTPSessions && ! $reachedSMTPlimit;
    # overall session limiting
    $maxSMTPSessions = 999999 if (! $maxSMTPSessions);
    if ($numsess >= $maxSMTPSessions) {
        if (! $reachedSMTPlimit) {
            $reachedSMTPlimit = 1;
            mlog(0,"warning : SMTP-session-limit $maxSMTPSessions is reached - SMTP listeners for incoming mails are temporary switched off");
            foreach my $lsn (@lsn ) {
                unpoll($lsn,$readable) if $lsn;
            }
            foreach my $lsn (@lsn2 ) {
                unpoll($lsn,$readable) if $lsn;
            }
            foreach my $lsn (@lsnSSL ) {
                unpoll($lsn,$readable) if $lsn;
            }
#            foreach my $lsn (@lsnRelay ) {
#                unpoll($lsn,$readable) if $lsn;
#            }
        }
    } else {
        if ($reachedSMTPlimit && ($maxSMTPSessions <= 5 || $maxSMTPSessions - $numsess > 20 || $numsess < int($maxSMTPSessions * 0.75))) {
            $reachedSMTPlimit = 0;
            mlog(0,"info : falling below SMTP-session-limit $maxSMTPSessions - SMTP listeners for incoming mails are now switched on");
            foreach my $lsn (@lsn ) {
                 &dopoll($lsn,$readable,POLLIN) if $lsn;
            }
            foreach my $lsn (@lsn2 ) {
                 &dopoll($lsn,$readable,POLLIN) if $lsn;
            }
            foreach my $lsn (@lsnSSL ) {
                 &dopoll($lsn,$readable,POLLIN) if $lsn;
            }
#            foreach my $lsn (@lsnRelay ) {
#                 &dopoll($lsn,$readable,POLLIN) if $lsn;
#            }
        }
    }
}
