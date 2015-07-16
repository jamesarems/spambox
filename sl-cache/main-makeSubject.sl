#line 1 "sub main::makeSubject"
package main; sub makeSubject {
    my $fh = shift;

    d('makeSubject');
    return if $Con{$fh}->{subject2} || ! $Con{$fh}->{headerpassed};
    my $sub;
    if (my ($header) = $Con{$fh}->{header} =~ /^($HeaderRe*)/o) {
        $sub = $1 if ($header =~ /(?:^|\012)Subject: *($HeaderValueRe)/iso);
        if (!$sub && $Con{$fh}->{maillogbuf} && (($header) = $Con{$fh}->{maillogbuf} =~ /^($HeaderRe*)/o)) {
            $sub = $1 if ($header =~ /(?:^|\012)Subject: *($HeaderValueRe)/iso);
        }
    }
    headerUnwrap($sub);
    return unless $sub;
    $sub =~ s/\r|\n|\t//go;
    $Con{$fh}->{subject2}=$sub;
    $Con{$fh}->{RFC2047} |= $Con{$fh}->{subject2} =~ s/$NONPRINT//go;
    $sub=decodeMimeWords2UTF8($sub);
    $sub = d8($sub);
    $Con{$fh}->{subject3} = $sub;
#    $Con{$fh}->{subject3} =~ s/\\x\{\d{2,}\}/_/go;
    $Con{$fh}->{subject3} =~ s/_{2,}/_/go;
    $sub =~ s/[^a-zA-Z0-9]/_/go;
    $sub =~ s/_{2,}/_/go;
    $Con{$fh}->{originalsubject} = $sub;
    $Con{$fh}->{originalsubject} =~ s/_/ /go;
    $Con{$fh}->{originalsubject} =~ s/\s+$//o;
    $Con{$fh}->{originalsubject} =~ s/^\s+//o;
    $Con{$fh}->{originalsubject} = $Con{$fh}->{subject3} if $UseUnicode4SubjectLogging;
    $Con{$fh}->{originalsubject} = substr($Con{$fh}->{originalsubject},0,50) .
                                   '...' .
                                   substr($Con{$fh}->{originalsubject},length($Con{$fh}->{originalsubject})-50,50)
                 if length($Con{$fh}->{originalsubject}) > 100;
    $Con{$fh}->{subject}=substr($sub,0,50);
    $Con{$fh}->{subject} = e8($Con{$fh}->{subject});
    $Con{$fh}->{originalsubject} = e8($Con{$fh}->{originalsubject});
    $Con{$fh}->{subject3} = e8($Con{$fh}->{subject3});
}
