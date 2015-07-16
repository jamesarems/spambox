#line 1 "sub main::HMMcleanUp"
package main; sub HMMcleanUp {
    my $line = shift;
    $line =~ s/\Q+-+***+!+\Etime:.+?\Q+-+***+!+\E//og;
    $line =~ s/\Q+-+***+!+\E(.+?)\Q+-+***+!+\E/$1/og;
    return unless $line;
    return $line if $line =~ /^(?:from|to|bcc|cc|mail from|rcpt to|sender|reply-to|errors-to|list-\w+|ReturnReceipt|Return-Receipt-To|Disposition-Notification-To):/io;
    return "!socket! !detected! $1!IP! $2" if $line =~ /^(connected ip: )(.+)$/io;
    return "!the! !geeting! !used! !was! helo $2" if $line =~ /^(helo\s+|ehlo\s+)(.+)$/io; # expand to fit in to 6 words (including the leading 'connected IP: ...'
    return $line if $line =~ /^(?:data|starttls)$/io;
    return if $line =~ /^mime-version:/io;
    return if $line =~ /^x-assp[^():]+?:/io;
    $line =~ s/by\s?\Q$myName\E.+//io;
    $line =~ s/\Q$myName\E with e?smtp.+//io;
    $line =~ s/helo=/helo= /ogi;
    $line =~ s/(?:\w{3},)?\s+\d?\d\s+\w{3}\s+\d{4}\s+\d?\d:\d\d:\d\d\s+[+-]?\d{1,4}//go;
    $line =~ s/[<>]//go;
    $line =~ s/(\@)/ $1/go;
    $line =~ s/([:;])([^\s])/$1 $2/go;
    $line =~ s/^\s+$//o;
    $line = $1.' randtag1 randtag2 randtag3 randtag4'.$2 if $line =~ /^(message-id:\s*)\S+( \@.+)$/io;

    our $h = 0; $line =~ s/(?:[a-f0-9]{2}){3,}(?{$h++;})/ randomhex$h /go;
    our $w = 0; $line =~ s/[a-z0-9][ghjklmnpqrstvwxz_]{2}[bcdfghjklmnpqrstvwxz_0-9]{3}\S*(?{$w++;})/ randomword$w /gio;

    $line =~ s/\s+/ /go;
    $line =~ s/^\s+//o;
    $line =~ s/\s+$//o;
    $line =~ s/^(?:(?:randomword|randomhex)\d+\s?)+$//igo;
    return $line;
}
