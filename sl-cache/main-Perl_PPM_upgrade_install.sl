#line 1 "sub main::Perl_PPM_upgrade_install"
package main; sub Perl_PPM_upgrade_install {
    my $area = shift;
    my $force = shift;
    my $ppm = shift;
    unless (@_) {
    	mlog(0, "perl-update: PPM - No missing packages to install");
    	return 0;
    }

    unless ($force) {
    	my $stop;
    	for my $pkg (@_) {
    	    if (my $why = $ppm->cannot_install($pkg)) {
        		mlog(0, "perl-update: PPM - Can't install ". $pkg->name_version. ": ". $why);
        		$stop++;
    	    }
    	}
    	if ($stop) {
    	    return 0;
    	}
    }

    unless ($area) {
    	$area = $ppm->default_install_area;
    	unless ($area) {
    	    my $msg = "All available install areas are readonly. Run 'ppm help area' to learn how to set up private areas.";
    	    require ActiveState::Path;
    	    if (ActiveState::Path::find_prog("sudo")) {
        		$msg .= "\nYou might also try 'sudo ppm' to raise your privileges.";
    	    }
    	    mlog(0, "perl-update: PPM - error - $msg");
            return 0;
    	}
    }
	mlog(0, "perl-update: PPM - Installing into $area");
    $area = $ppm->area($area);

    local $| = 1;

    chdir "$base/tmp";
    my $summary = $ppm->install(packages => \@_, area => $area, force => $force);
    if (my $count = $summary->{count}) {
    	for my $what (sort keys %$count) {
    	    my $n = $count->{$what} || 0;
    	    mlog(0, (sprintf "perl-update: PPM - %4d file%s %s\n", $n, ($n == 1 ? "" : "s"), $what));
    	}
        chdir "$base";
        return 1;
    }
    chdir "$base";
    return 0;
}
