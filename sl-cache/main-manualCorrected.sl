#line 1 "sub main::manualCorrected"
package main; sub manualCorrected {
    my @filelist;
    my $result;
    my $found = 0;
    my @list = $unicodeDH->("$base/$correctedspam/newManuallyAdded");
    while ( my $file = shift @list) {
        next if $dF->( "$base/$correctedspam/newManuallyAdded/$file" );
        next if ($file !~ /\Q$maillogExt\E$/i);
        $found++;
        $unlink->("$base/$correctedspam/$file");
        $newReported{"$base/$correctedspam/$file"} = 'spam'
            if $move->("$base/$correctedspam/newManuallyAdded/$file","$base/$correctedspam/$file");
        $unlink->("$base/$correctedspam/newManuallyAdded/$file");
    }
    @list = $unicodeDH->("$base/$correctednotspam/newManuallyAdded");
    while ( my $file = shift @list) {
        next if $dF->( "$base/$correctednotspam/newManuallyAdded/$file" );
        next if ($file !~ /\Q$maillogExt\E$/i);
        $found++;
        $unlink->("$base/$correctednotspam/$file");
        $newReported{"$base/$correctednotspam/$file"} = 'ham'
            if $move->("$base/$correctednotspam/newManuallyAdded/$file","$base/$correctednotspam/$file");
        $unlink->("$base/$correctednotspam/newManuallyAdded/$file");
    }
    return $found;
}
