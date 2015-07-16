#line 1 "sub main::saveSMTPconnections"
package main; sub saveSMTPconnections {
    mlog(0,"sig USR1 -- saving concurrent session stats");
    open (my $SMTP, '>',"$base/smtp.txt") ;
    print $SMTP "$smtpConcurrentSessions\n" ;
    close ($SMTP);
}
