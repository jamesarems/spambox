#line 1 "sub main::setPermission"
package main; sub setPermission {
    my ($dir,$perm,$subdirs,$print) = @_;
    $dir =~ s/\\/\//go;
    my @files;
    my $file;
    my $has;
    my $type;
    return if $dir =~ /\/certs$/io;
    return if $dir =~ /\/configdefaults\.txt$/io;
    if ($dF->( $dir )) {
        @files = $unicodeDH->($dir);
    } else {
        push @files,$dir;
    }
    $has = $chmod->( $perm, $dir);
    print "unable to set permission for directory $dir\n" if(! $has && $print);
    mlog(0, "unable to set permission for directory $dir") if(! $has && $print);
    return unless ($dF->( $dir ));
    while (@files) {
        $file = shift @files;
        next if $file eq '.';
        next if $file eq '..';
        next if $file =~ /^configdefaults\.txt$/io;
        $file = "$dir/$file";
        $type = $dF->( $file ) ? 'directory' : 'file' ;
        $has = $chmod->( $perm,$file ) if ($eF->( $file ));
        print "unable to set permission for $type $file\n" if(! $has && $print);
        mlog(0, "unable to set permission for $type $file") if(! $has && $print);
        &setPermission($file,$perm,$subdirs,$print) if ($dF->( $file ) && $subdirs);
    }
}
