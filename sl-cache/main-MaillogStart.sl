#line 1 "sub main::MaillogStart"
package main; sub MaillogStart {
    my $fh = shift;
    d('MaillogStart');
    $Con{$fh}->{maillog} = 1 unless $NoMaillog ;
    $Con{$fh}->{rcvd} =~ s/(with\sE?SMTPS?)A?/$1A/os if ($Con{$fh}->{authenticated} && $Con{$fh}->{chainMailInSession} < 1);
    if ("$fh" =~ /SSL/o) {
        my $sslv = eval{$fh->get_sslversion();};
        $sslv and $sslv = "$sslv ";
        my $ciffer = eval{$fh->get_cipher();};
        $ciffer = '' unless $ciffer;
        ($sslv || $ciffer) and $ciffer = '('.$sslv.$ciffer.')';
        $Con{$fh}->{rcvd} =~ s/(with\sE?SMTP)S?(A?)/$1S$2$ciffer/os if $Con{$fh}->{chainMailInSession} < 1;
    }
    $Con{$fh}->{maillogbuf}=$Con{$fh}->{header}=$Con{$fh}->{rcvd};
    if ($Con{$fh}->{crashfh}) {
        my $rcvd = $Con{$fh}->{rcvd};
        headerUnwrap($rcvd);
        $rcvd =~ s/by\s?\Q$myName\E .+$/\r\n/os;
        $Con{$fh}->{crashbuf} .= $rcvd;
        my $crashfh = $Con{$fh}->{crashfh};
        $crashfh->print($rcvd);
    }
}
