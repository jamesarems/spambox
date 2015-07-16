#line 1 "sub main::sendque"
package main; sub sendque {
    my ($fh,$message)=@_;
    my $outmessage = ref($message) ? $message : \$message;
    my $l=length($$outmessage);
    d("sq: $fh $Con{$fh}->{ip} l=$l");
    return unless $fh && exists $Con{$fh};

    if (   $Con{$fh}->{type} eq 'C'       # is a client SMTP connection?
        && ($replyLogging == 2 or ($replyLogging == 1 && $$outmessage =~ /^[45]/o))
        && $$outmessage =~ /^[1-5]\d\d\s+[^\r\n]+\r\n$/o)    # is a reply?
    {
        my $what = 'Reply';
        $$outmessage =~ s/SESSIONID/$Con{$fh}->{msgtime} $Con{$fh}->{SessionID}/go;
        $$outmessage =~ s/MYNAME/$myName/go;
        if ($$outmessage =~ /^([45])/o) {
            $what = ($1 == 5) ? 'Error' : 'Status';
        }
        my $reply = $$outmessage;
        $reply =~ s/\r?\n//o;
        mlog( $fh, "[SMTP $what] $reply", 1, 1 );
    }

    &dopoll($fh,$writable,POLLOUT);
    $Con{$fh}->{outgoing}.=$$outmessage;
    if(!$Con{$fh}->{paused} && length($Con{$fh}->{outgoing}) > $OutgoingBufSizeNew) {
        $Con{$fh}->{paused}=1;
        d('pausing');
        unpoll($Con{$fh}->{friend},$readable);
    }
}
