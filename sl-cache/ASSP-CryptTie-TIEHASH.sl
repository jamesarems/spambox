#line 1 "sub ASSP::CryptTie::TIEHASH"
package ASSP::CryptTie; sub TIEHASH {
    my ($ci,$pass,$bin,$how,$dbh)=@_;
    my $c = ref $ci || $ci;
    my ($db_module) = split(/,/o,$how);
    $db_module =~ s/\'|\"//go;
    $db_module =~ s/::/\//go;
    $how =~ s/\\/\//go;
    my $self = {};
    $self->{hash} = {};
    my $tiecmd = "\$tieobj = tie \%\{\$self->\{hash\}\} , $how ;1;";
    if ($db_module ne 'orderedtie') {
        eval{require "$db_module.pm";};  ## no critic
        die "$tiecmd - $@" if $@;
    }
    my $tieobj;
    eval($tiecmd);
    $self->{hashobj} = $tieobj;
    die "$tiecmd - $@" if $@;
    if ($db_module =~ /BerkeleyDB/o) {
        &main::BDB_filter($self->{hashobj});
    }

    $self->{hashobj}->{'noRDBMcache'} = 1;
    $self->{enc} = ASSP::CRYPT->new($pass,$bin);
    $self->{dec} = ASSP::CRYPT->new($pass,$bin);
    $self->{BIN} = $bin;
    $self->{doflush} = $db_module eq 'orderedtie' ? 1 : 0;

    my $fkey = $self->{hashobj}->FIRSTKEY;
    if (defined $fkey) {
        $fkey = $self->{dec}->DECRYPT($fkey);
        die 'ASSP::CRYPT ERROR: DATA and PASSPHRASE are incompatible!' unless defined $fkey;
    }

    bless $self, $c;

    # satisfy the selfloader
    if ($main::CanUseAsspSelfLoader && exists $AsspSelfLoader::Cache{'ASSP::CryptTie::DESTROY'}) {
        &DESTROY(0);
    }
    if ($main::CanUseAsspSelfLoader && exists $AsspSelfLoader::Cache{'ASSP::CryptTie::UNTIE'}) {
        $self->UNTIE(0);
    }

    return $self;
}
