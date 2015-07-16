#line 1 "sub main::BlockReportGenSched"
package main; sub BlockReportGenSched {
    my ($filename) = $BlockReportFile =~ /file:(.+)/io;
    my @files;
    push @files, $filename if $filename;
#    push @files, "files/UserBlockReportQueue.txt" if -e "$base/files/UserBlockReportQueue.txt";
    return unless @files;
    while ($filename = shift @files) {
        $filename = "$base/$filename";
        (open my $brfile,'<' ,"$filename") or next;
        my @lines = <$brfile>;
        close $brfile;
        while (@lines) {
            my $line = shift @lines;
            $line =~ s/#.*//o;
            $line =~ s/[\r\n]//og;
            next unless $line;
            my ($ad, $bd, $cd, $dd, $ed) = split(/=>/o,$line);
            next unless $ed;
            BlockReportAddSched($line);
        }
    }
}
