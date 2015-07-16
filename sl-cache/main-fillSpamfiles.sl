#line 1 "sub main::fillSpamfiles"
package main; sub fillSpamfiles {
    if ($RunTaskNow{'fillSpamfiles'}) {
        mlog(0,"info: the task 'fillSpamfiles' to register spamfile subjects is still running - this request is skipped");
        return 0;
    }
    $RunTaskNow{'fillSpamfiles'} = $WorkerNumber;
    return 0 unless $spamlog;
    return 0 unless $discarded;
    my %tSpamfiles = ();
    my %tSpamfileNames = ();
    my $count = 0;
    my @files = map {my $T = $_;$T=~/^([^\\\/]*)?--(\d+)\Q$maillogExt\E$/;($1 && $2)?($1,$2):('','');} $unicodeDH->("$base/$spamlog");
    while (@files) {
        my $file = shift @files;
        my $num = shift @files;
        next unless $file;
        next if /\\|\//o;
        next if $dF->( $file );
        $file = e8($file);
        my $md5 = eval{Digest::MD5::md5($file);};
        next unless $md5;
        $tSpamfileNames{$md5} .= ' ' if $tSpamfiles{$md5}++;
        $tSpamfileNames{$md5} .= "$num";
        $count++;
        &ThreadYield() if $count%100 == 0;
    }
    %Spamfiles = %tSpamfiles;
    %SpamfileNames = %tSpamfileNames;
    $RunTaskNow{'fillSpamfiles'} = '';
    mlog(0,"info: MaxAllowedDups - ".nN($count)." files registered in $Config{spamlog} folder") if $count;
    return $count;
}
