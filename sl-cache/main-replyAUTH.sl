#line 1 "sub main::replyAUTH"
package main; sub replyAUTH {
    my ($fh,$l)=@_;
    d('replyAUTH : ' . $l);
    my $friend = $Con{$Con{$fh}->{friend}};

    $Con{$friend}->{inerror} = ($l=~/^5[05][0-9]/o);
    $Con{$friend}->{intemperror} = ($l=~/^4\d{2}/o);
    if ($l=~/^(?:1|2|3)\d{2}/o) {
        delete $Con{$friend}->{inerror};
        delete $Con{$friend}->{intemperror};
    }

    if ($l =~ /^334\s*(.*)$/o) {
        $l = $1;
        if (exists $friend->{AUTHclient} && @{$friend->{AUTHClient}}) { # method PLAIN was used
            my $str = join ('', @{$friend->{AUTHClient}});              # send the authentication
            $str =~ s/[\r\n]+$//o;
            $str .= "\r\n";
            NoLoopSyswrite($fh,$str,0);
            @{$friend->{AUTHClient}} = ();
        } else {                                                        # any other method was used
            $l =~ s/[\r\n]+$//o;                                        # step by step procedure
            my @str = MIME::Base64::encode_base64(
                     $friend->{AUTHclient}->client_step(MIME::Base64::decode_base64($l), '')
                   );
            my $str = join ('', @str);
            $str =~ s/[\r\n]+$//o;
            $str .= "\r\n";
            NoLoopSyswrite($fh,$str,0) if $str;
        }
    } elsif ($l =~ /^235/o) {
        mlog($Con{$fh}->{friend}, "info: authentication successful") if $SessionLog >= 2;
        undef @{$friend->{AUTHClient}};
        delete $friend->{AUTHClient};
        delete $friend->{AUTHclient};
        &getline($Con{$fh}->{friend},$friend->{sendAfterAuth});
        $Con{$fh}->{getline}=\&reply;
    } else {
        $l =~ s/\r|\n//go;
        mlog($Con{$fh}->{friend}, "error: authentication failed ($l) - try to continue unauthenticated");
        undef @{$friend->{AUTHClient}};
        delete $friend->{AUTHClient};
        delete $friend->{AUTHclient};
        &getline($Con{$fh}->{friend},$friend->{sendAfterAuth});
        $Con{$fh}->{getline}=\&reply;
    }
}
