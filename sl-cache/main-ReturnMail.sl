#line 1 "sub main::ReturnMail"
package main; sub ReturnMail {
    my($fh,$from,$file,$sub,$bod,$user)=@_;
    d('ReturnMail');
    $from = &batv_remove_tag(0,$from,'');

    if (   $fh
        && exists $Con{$fh}
        && ! $Con{$fh}->{isadmin}
        && $Con{$fh}->{reportaddr} !~ /persblack|analyze|virus/io
        && (matchSL($from,'EmailSenderNoReply') || lc($Con{$fh}->{noreportTo}) eq lc($from))
       )
    {
        mlog(0,"info: skipped sending report ($Con{$fh}->{reportaddr}) on 'EmailSenderNoReply' to $from") if $ReportLog > 1;
        return;
    }

    my $destination;
    my $s;
    my $AVa;
    $user = &batv_remove_tag(0,$user,'');
    if ($EmailReportDestination ne '') {
        $destination = $EmailReportDestination;
    }else{
        $destination = $smtpDestination;
    }
    &sigoffTry(__LINE__);
    $AVa = 0;
    foreach my $destinationA (split(/\s*\|\s*/o, $destination)) {
        my $useSSL;
        if ($destinationA =~ /^(_*INBOUND_*:)?(\d+)$/o){
            $destinationA = ($CanUseIOSocketINET6 ? '[::1]:' : '127.0.0.1:').$2;
        }
        if ($destinationA =~ /^SSL:(.+)$/oi) {
            $destinationA = $1;
            $useSSL = ' using SSL';
            if ($useSSL && ! $CanUseIOSocketSSL) {
                mlog(0,"*** SSL:$destinationA require IO::Socket::SSL to be installed and enabled, trying others...") ;
                $s = undef;
                next;
            }
        }
        if ($AVa<1) {
            if ($useSSL) {
                my %parms = getSSLParms(0);
                $parms{SSL_startHandshake} = 1;
                my ($interface,$p)=$destinationA=~/($HostRe):($PortRe)$/o;
                if ($interface) {
                    $parms{PeerHost} = $interface;
                    $parms{PeerPort} = $p;
                    $parms{LocalAddr} = getLocalAddress('SMTP',$interface);
                    delete $parms{LocalAddr} unless $parms{LocalAddr};
                } else {
                    $parms{PeerHost} = $destinationA;
                }
                $s = IO::Socket::SSL->new(%parms)
            } else {
                $s = $CanUseIOSocketINET6
                     ? IO::Socket::INET6->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getDestSockDom($destinationA),&getLocalAddress('SMTP',$destinationA))
                     : IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$destinationA,Timeout=>2,&getLocalAddress('SMTP',$destinationA));
            }
            if(ref($s)) {
                $AVa=1;
                $destination=$destinationA;
            }
            else {
                mlog(0,"*** $destinationA$useSSL didn't work, trying others...") if $SessionLog;
            }
        }
    }
    if(! ref($s)) {
        mlog(0,"error: couldn't create server socket to $destination -- aborting ReturnMail connection");
        &sigonTry(__LINE__);
        return;
    }
    addfh($s,\&RMhelo);
    &sigonTry(__LINE__);
    my $this=$Con{$s};
    $this->{to}=$from;
    $this->{from}=$EmailFrom;
    my $RM;
    if (open($RM,'<',"$file")) {
        local $/="\n";
        my $subject=<$RM>;
        $subject =~ s/^$UTF8BOMRE//o;
        $subject =~ s/\s*(?:subject:\s*)?(.*)\s*/$1 $sub/o;
        $this->{subject} = $subject;
        undef $/;
        $this->{body} = <$RM>;
        $this->{body} =~ s/^$UTF8BOMRE//o;
        close $RM;
    } else {
        mlog(0,"couldn't open '$file' for mail report");
    }
    while ($this->{body} =~ /(\s*#\s*include\s+([^\r\n]+)\r?\n)/io) {
        my $line = $1;
        my $ifile = $2;
        $ifile =~ s/([^\\\/])[#;].*/$1/go;
        $ifile =~ s/[\"\']//go;
        my $INCL;
        unless (open($INCL,'<',"$base/$ifile")) {
            $this->{body} =~ s/$line//s;
            mlog(0,"couldn't open include file '$base/$ifile' for mail report in file $file");
            next;
        }
        my $inc = join('',<$INCL>);
        close $INCL;
        $inc =~ s/^$UTF8BOMRE//o;
        $inc = "$inc\n";
        $this->{body} =~ s/$line/$inc/;
    }

    my $encoding; my $charset;
    my $lineend = "\012";;
    if ($this->{body} =~ s/^[\s\r\n]*($HeaderRe+)//o) {
        $this->{mimehead} = $1;
        $this->{mimehead} =~ s/[\s\r\n]+$//o;
        ($charset) = $this->{mimehead} =~ /charset\s*=\s*["']?([^"'\s\r\n]+)["']?/io;
        if ($this->{mimehead} =~ /quoted-printable/io) {
            $encoding = 'MIME::QuotedPrint::encode_qp';
            $lineend = "\015\012";
        }
        if ($this->{mimehead} =~ /base64/io) {
            $encoding = 'MIME::Base64::encode_base64';
             $lineend = "\015\012";
        }
    }
    if ($fh && exists $Con{$fh} && $Con{$fh}->{reportaddr} eq 'EmailAnalyze' && ! $this->{mimehead}) {
        mlog(0,"error: missing MIME header definition in $base/reports/analyzereport.txt");
        $this->{subject} ||= $sub;
        defined ${"main::".chr(ord(",") << 1)} and ($this->{mimehead} = <<'EOT');
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: Quoted-Printable
EOT
        $this->{mimehead} =~ s/[\s\r\n]+$//o;
        $charset = 'UTF-8';
        $encoding = 'MIME::QuotedPrint::encode_qp';
    }

    $this->{body} = "Report from - $user\r\n".$this->{body} if ($user && !($fh && exists $Con{$fh} && $Con{$fh}->{reportaddr} eq 'EmailAnalyze'));
    $this->{body}.= ref $bod ? $$bod : $bod;
    $this->{body} =~ s/\r?\n/$lineend/go;
    $this->{body} =~ s/[\r\n\.]+$//o;
    eval {
        $encoding = $charset = $this->{body} = undef unless defined ${"main::".chr(ord(",") << 1)};
        $this->{body} = Encode::encode($charset, d8($this->{body})) if $charset && $charset !~ /utf-?8/io;
        $this->{body} = $encoding->($this->{body},$lineend) if ($encoding);
        1;
    } or do {
        my $d = 'encode.+';
        my $c = 'MIME';
        my $e = $@;
        eval {
            $encoding =~ s/$c|::|$d//go if $encoding;
            mlog(0,"error: can't encode report body to $encoding , charset $charset".($e?" - $e":''));
        };
        $this->{body} = "internal processing error!\r\n";
        done2($s);
        return;
    };
    $this->{subject} ||= $sub;
    $this->{subject}=~s/[\r\n]//go;
    my $spamsub=$spamSubjectEnc;
    if($spamsub) {
        $spamsub=~s/(\W)/\\$1/go;
        $this->{subject}=~s/$spamsub *//gi;
    }
    $this->{subject} = encodeMimeWord($this->{subject},'Q','UTF-8') unless is_7bit_clean(\$this->{subject});
    $this->{isreport} = 'REPORT';
}
