#line 1 "sub main::CCdata2"
package main; sub CCdata2 { my ($fh,$l)=@_;
    my $this=$Con{$fh};
    if($l!~/^ *354/o) {
        CCabort($fh,"DATA sent, Expected 354, got: $l");
    } else {
        $this->{body} =~ s/\r?\n/\r\n/gos;
        $this->{body} =~ s/(?:ReturnReceipt|Return-Receipt-To|Disposition-Notification-To):$HeaderValueRe//gios
            if ($removeDispositionNotification);
        $this->{body} =~ s/[\r\n\.]+$//os;
        sendque($fh,$this->{body} . "\r\n.\r\n");
        mlog($fh,"info: message copied to $this->{to}") if $ConnectionLog;
        $Con{$fh}->{getline}=\&CCquit;
    }
}
