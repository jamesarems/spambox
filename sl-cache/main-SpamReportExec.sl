#line 1 "sub main::SpamReportExec"
package main; sub SpamReportExec {
    my ($bod,$path,$from)=@_;
    d('SpamReportExec');
    my $header;
    my ($sub) = $bod =~ /(?:^|\n)Subject:\s*($HeaderValueRe)/ios;
    ($sub) = $bod =~ /X-Assp-Original-Subject:\s*($HeaderValueRe)/ios unless $sub;
    $sub =~ s/[\r\n]+$//o;
    my $udecsub = $sub;
    $sub=decodeMimeWords2UTF8($sub);
    $sub=~s/^(?:(?:\S{2,}?:)|(?:[^\]]*\])\s)+//io;

    # remove the spam subject header addition if present
    my $spamsub=$spamSubjectEnc;
    if($spamsub) {
        $spamsub=~s/(\W)/\\$1/go;
        $sub=~s/$spamsub//gi;
        $udecsub=~s/$spamsub//gi;
    }
    $sub =~ s/\r//o;
    $udecsub =~ s/\r//o;

    my $encsub = $sub =~ /[\x00-\x1F\x7F-\xFF]/o ? $udecsub : $sub;
    $header = "X-Assp-Reported-By: $from\r\n" if $from;
    $header.="Subject: ".$encsub."\r\n" if $encsub;
    $header.=$1."\r\n" if $bod=~/(Received:\s+from\s+.*?\(\[$IPRe.*?helo=.*?\))/io;
    $sub =~ y/a-zA-Z0-9/_/cs unless $UseUnicode4SubjectLogging;
    $sub =~ s/[\^\s\<\>\?\"\:\|\\\/\*]/_/igo;  # remove not allowed characters and spaces from file name

    $header.=$1 if $bod=~/(X-Assp-ID: .*)/io;

    $header.=$1 if $bod=~/(X-Assp-Tag: .*)/io;

    $header.=$1 if $bod=~/(X-Assp-Envelope-From: .*)/io;

    $header.=$1 if $bod=~/(X-Assp-Intended-For: .*)/io;

    $bod=~s/^.*?\n[\r\n\s]+//so;

    $bod=~s/X-Assp-Spam-Prob:[^\r\n]+\r?\n//gio;
    if($bod=~/\nReceived: /o) {
        $bod=~s/^.*?\nReceived: /Received: /so;
    } else {
        $bod=~s/^.*?\n((\w[^\n]*\n)*Subject:)/$1/sio;
        $bod=~s/\n> /\n/go;
    }
    $bod=$header.$bod;

    my $f;
    my $file;
    
    do {
        $f = int( rand() * 100000 );
        $file = $sub ? "$base/$path/$sub--$f.rpt".$maillogExt : "$base/$path/$f.rpt".$maillogExt;
    } while ($eF->( $file ));
    
    $open->(my $SR,'>',$file) or return $sub;
    $SR->binmode;
    $SR->print($bod);
    $SR->close;
    $eF->( $file ) && ($newReported{$file} = ($path eq $correctedspam) ? 'spam' : 'ham');
    threads->yield();
    mlog(0,"info: report message written to -> ".de8($file)) if $ReportLog;
    $sub;
}
