#line 1 "sub main::modListOnEdit"
package main; sub modListOnEdit {
    my ($reportaddr, $to, $mail, $fh) = @_;
    $fh ||= 'modListOnEdit';
    $Con{$fh}->{reportaddr} = $reportaddr;
    return unless $EmailAdminReportsTo;
    my $mailfrom = $Con{$fh}->{mailfrom};
    my $header = $Con{$fh}->{header};
    $Con{$fh}->{mailfrom} = $EmailAdminReportsTo || $to;
    $Con{$fh}->{header} = ${$mail};
    for my $addr (&ListReportGetAddr($fh)) {
        &ListReportExec($addr,$Con{$fh});
    }
    $Con{$fh}->{mailfrom} = $mailfrom ;
    $Con{$fh}->{header} = $header;
    my $ret = $Con{$fh}->{report};
    $ret =~ s/^(?:\s|\r|\n)+//o;
    $ret =~ s/\r?\n/<br \/>/gos;
    $ret = '<br />'.$ret if $ret;
    delete $Con{$fh} if $fh eq 'modListOnEdit';
    return $ret;
}
