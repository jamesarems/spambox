#line 1 "sub main::configUpdateSPFCheckRecord"
package main; sub configUpdateSPFCheckRecord {
    my ($mfd,$rec) = @_;
    my $spf_server = Mail::SPF::Server->new();
    my $version = ($rec =~ /\s*v\s*=\s*spf1/io) ? 1 : 2;
    $rec = SPF_get_records_from_text($spf_server, $rec, 'TXT', $version, 'mfrom', $mfd);
    return $rec if $rec;
    $rec = SPF_get_records_from_text($spf_server, $rec, 'TXT', $version, 'helo', $mfd);
    return $rec if $rec;
    die "error: SPF2 record check failed - record '$rec' has no scope for 'mfrom' or 'helo' or another error occured\n";
}
