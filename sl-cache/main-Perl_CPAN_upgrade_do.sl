#line 1 "sub main::Perl_CPAN_upgrade_do"
package main; sub Perl_CPAN_upgrade_do {
    my $upg_package = shift;
    my %avail;
    my $install;
    $install++ if $upg_package ;
    $upg_package = '' if $upg_package eq '--install';
    my $upg_running;
    my $upgrade_count;
    my @modules;
    d('CPAN - module upgrade');
    ThreadMaintMain2();
    my %skipModule = Perl_no_upgrade();
    eval {
        chdir "$base/tmp";
        CPAN::Shell->o(qw(conf prerequisites_policy follow));
        CPAN::Shell->o(qw(conf connect_to_internet_ok yes));
        CPAN::Shell->o(qw(conf commit));
        @modules =  map {
                        $_->[1]
                    } sort {
                        $b->[0] <=> $a->[0]
                        ||
                        $a->[1]{ID} cmp $b->[1]{ID}
                    } map {
                        [ $_->_is_representative_module, $_ ]
                    } CPAN::Shell->expand('Module',CPAN::Shell->r);
        foreach ( @modules ) {
            next if ($upg_package && $_->id ne $upg_package);
            $avail{$_->id} = $_->cpan_version;
            $upgrade_count++;
        }
        if ($install) {
            foreach ( @modules ) {
                return wantarray ? %avail : $upgrade_count if(! $ComWorker{$WorkerNumber}->{run});
                ThreadMaintMain2();
                next if $skipModule{$_->id};
                next if ($upg_package && $_->id ne $upg_package);
                mlog(0,"perl-update: CPAN - update module ".$_->id." from version ".$_->inst_version." to version ".$_->cpan_version);
                eval { CPAN::Shell->install($_->id); Perl_upgrade_log($_->id,$_->inst_version,$_->cpan_version); 1;} or do {
                    mlog(0,"perl-update: CPAN - error - failed to updated module ".$_->id);
                    next;
                };
                delete $avail{$_->id};
                $upg_running ||= exists ${'::'}{$_->id.'::'};
                $upgrade_count--;
            }
        }
    };
    eval('
    no CPAN::Shell;
    no CPAN;
    ');
    $codeChanged = 2 if $upg_running;
    chdir "$base";
    return wantarray ? %avail : $upgrade_count;
}
