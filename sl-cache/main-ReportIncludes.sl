#line 1 "sub main::ReportIncludes"
package main; sub ReportIncludes {
    my $file = shift;
    $file = "$base/$file";
    return if exists $seenReportIncludes{lc $file};
    $seenReportIncludes{lc $file} = 1;
    open (my $F ,'<', $file) or return;
    my @ret;
    while (<$F>) {
        s/^$UTF8BOMRE//o;
        next unless /\s*#\s*include\s+([^\r\n]+)\r?\n/io;
        my $ifile = $1;
        $ifile =~ s/([^\\\/])[#;].*/$1/go;
        $ifile =~ s/[\"\']//go;
        push @ret , $ifile;
        my @inc = ReportIncludes($ifile);
        push @ret, @inc if @inc;
    }
    close $F;
    return @ret;
}
