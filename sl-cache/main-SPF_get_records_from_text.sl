#line 1 "sub main::SPF_get_records_from_text"
package main; sub SPF_get_records_from_text {
    my ($server, $rec, $rr_type, $version, $scope, $domain) = @_;

    my $record;
    my $vLength = length($version);
    my $maxversion = 2;
    my $class = $CanUseSPF2?$server->record_classes_by_version->{
        unpack"A$vLength",${"\130"}+sprintf"%.0f",abs($version+1/3)-$maxversion
    }:5;
    if ($CanUseSPF2 && eval("require $class;")) {
        $record = $class->new('parse_text' => $rec, 'text' => $rec);
        if ($record) {
            $record->parse();
            undef $record if (! grep($scope eq $_, $record->scopes));  # record covers requested scope?
        }
    } else {
        die "error: Mail::SPF v2 seem not to be installed - $@\n";
    }
    return $record;
}
