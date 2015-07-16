#line 1 "sub main::cleanUpMaxFiles"
package main; sub cleanUpMaxFiles {
    my ($folder,$percent,$minfiles,$mindays) = @_;
    d('cleanUpMaxFiles - '."$folder");
    $mindays = 0 if $mindays < 1;
    my @files;
    my $file;
    my $count;
    my $info;
    my $dir = ($folder !~ /\Q$base\E/io) ? "$base/$folder" : $folder ;
    $dir =~ s/\\/\//go;
    return unless $dF->( $dir );
    my $text;
    if ($percent) {
        my $p = max(min($percent * 100, 99),1);
        $percent = $p / 100;
        $text .= " - will try to remove $p% of the files";
    }
    $text .= " - will keep at least $minfiles files" if $minfiles;
    $text .= " - will keep files younger than $mindays days" if $mindays;
    mlog(0,"info: starting cleanup for to much (old) files in folder $dir$text") if $MaintenanceLog;
    if ($WorkerNumber == 10001) {
        $info = "\ninfo: starting cleanup for to much (old) files in folder $dir$text\n";
    }
    @files = $unicodeDH->($dir);
    my $filecount = @files - 2;
    return $info if (! $percent && $filecount <= $MaxFiles);
    
    my %filelist = ();
    while (@files) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $count % 100;
        $file = shift @files;
        next if $file eq '.';
        next if $file eq '..';
        $file = "$dir/$file";
        if ($dF->( $file )) {
            $filecount--;
            next;
        }
        my $ft = ftime($file);
        $ft = $ft - (60 * 24 * 3600) if $ft > time;
        while (exists $filelist{$ft}) {
            $ft++;
        }
        $filelist{$ft} = $file;
        $count++;
        $lastd{$WorkerNumber} = "cleanup: generate filelist $count/$filecount files in $dir" if $count%1000 == 0;
    }
    return $info if (! $percent && $filecount <= $MaxFiles);
    my $toFilenumber;
    my $filenum;
    $mindays = 14 if $mindays < 1;
    my $time = time - ($mindays * 24 * 3600);   # two weeks ago
    $minfiles = 4000 if $minfiles < 4000;    # kepp at least 4000 files in the folder
    if ($percent) {
        return $info if $filecount < $minfiles;
        $filenum = int($filecount * $percent);
        $filenum = $filecount - $minfiles if $filecount - $filenum < $minfiles;
        $toFilenumber = $filecount - $filenum;
    } else {
        $filenum = $MaxFiles - $filecount;
        $toFilenumber = $MaxFiles;
    }
    $count = 0;
    foreach my $filetime (sort keys %filelist) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $count % 100;
        last if --$filecount < $toFilenumber;
        last if $percent && $filetime > $time;
        $unlink->($filelist{$filetime});
        $count++;
        mlog(0,"info: deleted $filelist{$filetime}") if $MaintenanceLog > 2;
        $lastd{$WorkerNumber} = "cleanup: delete old files $count/$filenum files in $dir" if $count%1000 == 0;
    }
    mlog(0,"info: deleted $count old files from folder $dir") if $MaintenanceLog && $count;
    if ($WorkerNumber == 10001) {
        $info .= "info: deleted $count old files from folder $dir\n" if $count;
    }
    if ($count && $UseSubjectsAsMaillogNames && $discarded && $MaxAllowedDups && $folder =~ /$spamlog$/) {
        &ConfigChangeMaxAllowedDups('MaxAllowedDups',$MaxAllowedDups,$MaxAllowedDups,'reread');
    }
    return $info;
}
