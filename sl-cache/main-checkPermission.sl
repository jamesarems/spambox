#line 1 "sub main::checkPermission"
package main; sub checkPermission {
    my ($dir,$perm,$subdirs,$print) = @_;
    $dir =~ s/\\/\//go;
    my @files;
    my $file;
    my $has;
    my $type;
    if ($dF->( $dir )) {
        @files = $unicodeDH->($dir);
    } else {
        push @files,$dir;
    }
    $has = [$stat->($dir)]->[2];
    $has=sprintf("0%o", $has & oct('07777'));
    print "permission for directory $dir is $has - should be at least $perm\n" if($has < $perm && $print);
    mlog(0, "permission for directory $dir is $has - should be at least $perm") if($has < $perm && $print);
    return unless ($dF->( $dir ));
    while (@files) {
        $file = shift @files;
        next if $file eq '.';
        next if $file eq '..';
        $file = "$dir/$file";
        $type = $dF->( $file ) ? 'directory' : 'file' ;
        $has = [$stat->($file)]->[2];
        $has=sprintf("0%o", $has & oct('07777'));
        print "permission for $type $file is $has - should be at least $perm\n" if($has < $perm && $print);
        mlog(0, "permission for $type $file is $has - should be at least $perm") if($has < $perm && $print);
        print "$type $file is not writeable with this job - it has a wrong permission, or is still opened by another process!\n" if($type eq 'file' && ! -w $file && $print);
        mlog(0, "$type $file is not writeable with this job - it has a wrong permission, or is still opened by another process!") if($type eq 'file' && ! -w $file && $print);
        &checkPermission($file,$perm,$subdirs,$print) if ($dF->( $file ) && $subdirs);
    }
}
