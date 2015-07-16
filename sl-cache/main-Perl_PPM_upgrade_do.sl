#line 1 "sub main::Perl_PPM_upgrade_do"
package main; sub Perl_PPM_upgrade_do {
    my $upg_package = shift;
    my %repo;
    d('PPM - module upgrade');
    chdir "$base/tmp";
    $repo{'5.10'} = {
        'trouchelle.510' => 'http://trouchelle.com/ppm10',
        'trouch-act' => 'http://trouchelle.com/ppm10/activestate/1000/',
        'uni_winnipeg.510' => 'http://cpan.uwinnipeg.ca/PPMPackages/10xx/',
        'bribes.org' => 'http://www.bribes.org/perl/ppm/',
        "$base\\assp.mod" => 'file:///'.$base.'/assp.mod/',
        'ASSP2' => 'http://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/packages/'
    };
    $repo{'5.12'} = {
        'trouchelle.512' => 'http://trouchelle.com/ppm12',
        'uni_winnipeg.512' => 'http://cpan.uwinnipeg.ca/PPMPackages/12xx/',
        'bribes.org' => 'http://www.bribes.org/perl/ppm/',
        "$base\\assp.mod" => 'file:///'.$base.'/assp.mod/',
        'ASSP2' => 'http://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/packages/'
    };
    $repo{'5.14'} = {
        'trouchelle.514' => 'http://trouchelle.com/ppm14',
        'uni_winnipeg.514' => 'http://cpan.uwinnipeg.ca/PPMPackages/14xx/',
        'bribes.org' => 'http://www.bribes.org/perl/ppm/',
        "$base\\assp.mod" => 'file:///'.$base.'/assp.mod/',
        'ASSP2' => 'http://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/packages/'
    };
    $repo{'5.16'} = {
#        'trouchelle.516' => 'http://trouchelle.com/ppm16',
#        'uni_winnipeg.516' => 'http://cpan.uwinnipeg.ca/PPMPackages/16xx/',
        'bribes.org' => 'http://www.bribes.org/perl/ppm/',
        "$base\\assp.mod" => 'file:///'.$base.'/assp.mod/',
        'ASSP2' => 'http://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/packages/'
    };
    $repo{'5.18'} = {
        'bribes.org' => 'http://www.bribes.org/perl/ppm/',
        "$base\\assp.mod" => 'file:///'.$base.'/assp.mod/',
        'ASSP2' => 'http://downloads.sourceforge.net/project/assp/ASSP%20V2%20multithreading/packages/'
    };
    my $ppm = ActivePerl::PPM::Client->new;
    my $install;
    my %avail;
    my $upg_running;
    my $sync = 1;

    $install++ if $upg_package ;
    $upg_package = '' if $upg_package eq '--install';
    my $pkg_count = 0;
    my %shaddow;
    my %shaddow2;
    my $vstr = $];
    $vstr =~ s/^(\d\.)0(\d\d).*$/$1$2/o;
    mlog(0,"perl-update: checking PPM repositories for Perl $vstr");
    if (! exists $repo{$vstr} ) {
        mlog(0,"perl-update: error - Perl $vstr is not supported by ASSP");
        return ;
    }
    my %rep;
    for ($ppm->repos) {$rep{ $ppm->repo($_)->{name} }++ ;}
    while ( my ($k,$v) = each %{$repo{$vstr}} ) {
        if ($rep{$k} > 1) {
            for ($ppm->repos) {$ppm->repo($_)->{name} eq $k && eval{$ppm->repo_delete($_);};}
            delete $rep{$k};
        }
        next if $rep{$k};
        eval{$ppm->repo_add('name' => $k, 'packlist_uri' => $v);};
        ThreadMaintMain2();
    }
    my @rep;
    $ppm->repo_sync if $sync;
    ThreadMaintMain2();
    for ($ppm->repos) {push @rep, $ppm->repo($_)->{name};}
    mlog(0,"perl-update: using the following PPM repositories: \n".join("\n",@rep));
    my %skipModule = Perl_no_upgrade();
    for my $area_name ($ppm->areas) {
    	my $area = $ppm->area($area_name);
    	my $newfound;
        my @pack;
    	for ($area->packages("id", "name", "version")) {
            my $pack = $_;
    	    my($pkg_id, $pkg_name, $pkg_version) = @$_;
    	    return wantarray ? %avail : $pkg_count if(! $ComWorker{$WorkerNumber}->{run});
    	    ThreadMaintMain2();
    	    next if $upg_package && lc($upg_package) ne lc($pkg_name);
    	    next if $shaddow2{$pkg_name}++;
    	    eval {
        	    if (my $best = $ppm->package_best($pkg_name, 0)) {
            		if ($best->{name} eq $pkg_name && $best->{version} ne $pkg_version) {
            		    my $pkg = $area->package($pkg_id);
            		    if ($best->better_than($pkg)) {
                            push @pack, $pack;
                			$avail{$pkg_name} = $best->{version};
    	                    $pkg_count++;
    	                    $newfound = 1;
                		}
                	}
                }
            };
    	}
    	next if ( ! $install || ! $newfound);
    	ThreadMaintMain2();
    	for (@pack) {
    	    my($pkg_id, $pkg_name, $pkg_version) = @$_;
    	    ThreadMaintMain2();
    	    return wantarray ? %avail : $pkg_count if(! $ComWorker{$WorkerNumber}->{run});
            next if $skipModule{$pkg_name};
    	    next if $upg_package && lc($upg_package) ne lc($pkg_name);
    	    next if $shaddow{$pkg_name}++;
    	    eval {
        	    if (my $best = $ppm->package_best($pkg_name, 0)) {
            		if ($best->{name} eq $pkg_name && $best->{version} ne $pkg_version) {
            		    my $pkg = $area->package($pkg_id);
            		    if ($best->better_than($pkg)) {
                			mlog(0, "perl-update: PPM - $pkg_name $best->{version} (have $pkg_version)");
                			if ($install) {
                			    my $install_area = $area_name;
                			    if ($install_area eq "perl" || $area->readonly) {
                    				$install_area = $ppm->default_install_area;
                    				unless ($install_area) {
                    				    mlog(0, "perl-update: PPM - No writable install area for the upgrade of module $pkg_name");
                                        next;
                    				}
                			    }
                			    if (Perl_PPM_upgrade_install($install_area, 0, $ppm ,$best)) {
                                    delete $avail{$pkg_name};
                                    Perl_upgrade_log($pkg_name,$pkg_version,$best->{version});
                                    $upg_running ||= exists ${'::'}{$pkg_name.'::'};
                                    $pkg_count--;
                			    }
                			}
            		    }
            		}
        	    }
    	    };
    	    if ($@) {
    		    mlog(0, "perl-update: PPM - error $@");
                if ($@ =~ /Can't save to (.+?\.ppmbak) /io) {
                    mlog(0,"perl-update: PPM - removed obsolet backup file '$1' for the next update") if unlink($1);
                }
    	    }
    	}
    }
    eval('
    no ActivePerl::PPM::Util;
    no ActivePerl::PPM::Logger;
    no ActivePerl::PPM::Web;
    no ActivePerl::PPM::Client;
    no ActivePerl::PPM::limited_inc;
    ');
    $codeChanged = 2 if $upg_running;
    return wantarray ? %avail : $pkg_count;
}
