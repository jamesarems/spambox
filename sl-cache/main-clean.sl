#line 1 "sub main::clean"
package main; sub clean {
    my $m = shift;

    my $msg = ref($m) ? $$m : $m;
    my $t = time + $BayesMaxProcessTime;     # max 15 seconds for this cleaning
    my $body;
    my $header;
    my $undec = 1;

    $body = cleanMIMEBody2UTF8(\$msg);

    if ($body || $msg =~ /^$HeaderRe/o) {
        $header = cleanMIMEHeader2UTF8(\$msg,0);
        headerUnwrap($header);
        $undec = 0;
    }

    local $_= "\n". (($header) ? $header : $msg);
    my ($helo,$rcpt);
    if ($header) {
        ($helo)=/helo=([^)]+)\)/io;
        $helo = substr($helo,0,25); # if the helo string is long, break it up
        my (@sender,@receipt,$sub);
        while (/($HeaderNameRe):($HeaderValueRe)/igos) {
            my($head,$val) = ($1,$2);
            next if $head =~ /^(?:x-assp|(?:DKIM|DomainKey)-Signature)|X-Original-Authentication-Results/oi;
            if ($head =~ /^(to|cc|bcc)$/io) {
                push @receipt, $1 while ($val =~ /($EmailAdrRe\@$EmailDomainRe)/gio);
            }
            if ($head =~ /^(?:from|ReturnReceipt|Return-Receipt-To|Disposition-Notification-To|Return-Path|Reply-To|Sender|Errors-To|List-\w+)/io) {
                push @sender, $1 while ($val =~ /($EmailAdrRe\@$EmailDomainRe)/gio);
            }
            if ($head =~ /^(subject)$/io) {
                Encode::_utf8_on($val);
                $sub = fixsub($val);
            }
        }
        $rcpt = ' rcpt ' . join(' rcpt ',@receipt) if scalar @receipt;
        $rcpt .= ' sender ' . join(' sender ',@sender) if scalar @sender;
        # mark the subject
        $rcpt .= "\n".$sub if $sub;
        return "helo: $helo\n$rcpt\n",0 if (time > $t);
    }

    # from now only do the body if possible
    return "helo: $helo\n$rcpt\n",1 unless $body;
    local $_ = $body;

    # replace HTML encoding
    s/&amp;?/and/gio;
    $_ = decHTMLent($_);
    return "helo: $helo\n$rcpt\n",0 if (time > $t);

    if ($undec) {
      # replace base64 encoding
      s/\n([a-zA-Z0-9+\/=]{40,}\r?\n[a-zA-Z0-9+\/=\r\n]+)/base64decode($1)/gseo;

      # clean up quoted-printable references
      s/(Subject: .*)=\r?\n/$1\n/o;
      s/=\r?\n//go;
      # strip out mime continuation
      s/.*---=_NextPart_.*\n//go;
      return "helo: $helo\n$rcpt\n",0 if (time > $t);
    }
    # clean up MIME quoted-printable line breakings
    s/=\r?\n//gos;

    # clean up &nbsp; and &amp;
#    s/(\d),(\d)/$1$2/go;
    s/\r//go; s/ *\n/\n/go;
    s/\n\n\n\n\n+/\nblines blines\n/go;
    return "helo: $helo\n$rcpt\n",0 if (time > $t);

    # clean up html stuff
    s/<\s*(head)\s*>.*?<\/\s*\1\s*>//igos;
    s/<\s*(title|h\d)\s*>(.*?)<\/\s*\1\s*>/fixsub($2)/igse;
    s/<\s*((?:no)?script)[^>]+>.*?<\s*\/\s*\1\s*>/ jscripttag /igs;
    s/<\s*(?:no)?script[^>]+>/ jscripttag /igos;
    return "helo: $helo\n$rcpt\n",0 if (time > $t);
    # remove style sheets
    s/<\s*style[^>]*>(.*?)<\s*\/\s*style\s*>/$1/iogs;
    s/<\s*select[^>]*>(.*?)<\s*\/\s*select\s*>/$1/iogs;
    # remove comments
    s/(?:<!--.*?-->|<([^>\s]+)[^>]*\s+style=['"]?[^>'"]*(?:display:\s*none|visibility:\s*hidden)[^>'"]*['"]?[^>]*>.*?<\/\1\s*>)//igs;
    s/<\s*\?\s*php[^>]*?\?\s*>/ jscripttag /igso;
    s/<\s*!\s*[a-z].*?>//igso;
    return "helo: $helo\n$rcpt\n",0 if (time > $t);

    s/<\s*(?:[biu]|strong)\s*>/ boldifytext /gio;

    # remove some tags that are not informative
    s/<\s*\/?\s*(?:p|br|div|t[drh]|li|dd|[duo]l|center|form|input)[^>]*>/\n/gios;
    s/<\s*\/?\s*(?:[biuo]|strong)\s*>//gio;
    s/<\s*\/?\s*(?:html|meta|head|body|span|table|font|col|map)[^>]*>//igos;
    return "helo: $helo\n$rcpt\n",0 if (time > $t);

    # look for linked images
    s/(<\s*a[^>]*>[^<]*<\s*img)/ linkedimage $1/giso;
    s/<[^>]*href\s*=\s*("[^"]*"|\S*)/ href $1 /isgo;
    s/(<\s*a\s[^>]*>)(.*?)(<\s*\/a\s*>)/$1.fixlinktext($2)/igseo;

    s/((?:ht|f)tps?\S*)/ href $1 /isgo;
    return "helo: $helo\n$rcpt\n",0 if (time > $t);

    s/(\S+\@\S+\.\w{2,5})\b/ href $1 /go;
    s/<?\s*img .{0,50}src\s*=\s*['"]([^'"]*)['"][^>]+>/$1/gois;
    s/["']\s*\/?s*>|target\s*=\s*['"]?_blank['"]?|<\s*\/|:\/\/ //go;
    s/ \d{2,} / 1234 /go;
    $msg = &decHTMLent($_);
    if ($CanUseSPAMBOX_WordStem) {
        my $ret = eval{&SPAMBOX_WordStem::process($msg);};
        if ($ret) {
            return ("helo: $helo\n$rcpt\n".$ret,1);
        } else {
            fixutf8(\$msg);
            return ("helo: $helo\n$rcpt\n$msg",1);
        }
    } else {
        fixutf8(\$msg);
        return ("helo: $helo\n$rcpt\n$msg",1);
    }
}
