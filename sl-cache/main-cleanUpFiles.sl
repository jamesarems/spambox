#line 1 "sub main::cleanUpFiles"
package main; sub cleanUpFiles {
    my ($folder, $filter, $filetime) = @_;
    d('cleanUpFiles - '."$folder, $filter, $filetime");
    my $textfilter; $textfilter = " (*$filter)" if $filter;
    my @files;
    my $file;
    my $count;
    my $filecount;
    my $filemax;
    my $dir = ($folder !~ /\Q$base\E/io) ? "$base/$folder" : $folder ;
    $dir =~ s/\\/\//go;
    return unless $eF->( $dir );
    mlog(0,"info: starting cleanup old files$textfilter for folder $dir") if $MaintenanceLog >= 2;
    @files = $unicodeDH->($dir);
    $filemax = @files;
    while (@files) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $filecount % 100;
        $file = shift @files;
        $filecount++;
        $lastd{10000} = "cleanup: delete old files$textfilter: $filecount/$filemax files processed in $dir" if $filecount%1000 == 0;
        next if $file eq '.';
        next if $file eq '..';
        next if ($filter && $file !~ /$filter$/i);
        next if ($filter && $file =~ /^$filter$/i);
        $file = "$dir/$file";
        next if $dF->( $file );
        if (ftime($file) - time < $filetime * -1) {
            $unlink->($file) and
            $count++ and ($MaintenanceLog > 2) and
            mlog(0,"info: deleted $file");
        }
    }
    mlog(0,"info: deleted $count old$textfilter files from folder $dir") if $MaintenanceLog && $count;
}
