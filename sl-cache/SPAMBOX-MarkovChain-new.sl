#line 1 "sub SPAMBOX::MarkovChain::new"
package SPAMBOX::MarkovChain; sub new {
    my $invocant = shift;
    my %args = @_;
    &DESTROY();
    my $class = ref $invocant || $invocant;
    my $self = {};
    bless $self, $class;
    # $self->{simple} values
    # 0 or undef - do complex HMM
    # 1 - simple HMM in BDB
    # 2 - any HMM given in args
    # 3 - simple HMM in Storable
    if ($args{BDB}) {
        push @{$self->{q}},chr($_+16*4)for(1..3);($self->{simple}=
        eval{   ($self->{q}->[0] = $main::CanUseBerkeleyDB)
             && ($self->{q}->[1] = defined(${'main::'.chr(ord(',') << 1)}))
             && ($self->{q}->[2] = defined(${'main::lockHMM'}))
        }) || do {
            my $ret = 'error: SPAMBOX::MarkovChain internal exception('.join(',',@{$self->{q}}).')';
            undef $self;
            &main::mlog(0,$ret);
            return $ret;
        };
        $self->{chains} = {};
        $self->{totals} = {};
        eval{
            my $file = $args{BDB}->{'-Filename'};
            $args{BDB}->{'-Filename'} .= '.bdb';
            $self->{chainsDB} = tie %{$self->{chains}},'BerkeleyDB::Hash',$args{BDB};
            $args{BDB}->{'-Filename'} = $file.'.totals.bdb';
            $self->{totalsDB} = tie %{$self->{totals}},'BerkeleyDB::Hash',$args{BDB};
            1;
        } || do {
            my $e = $@;
            undef $self;
            my $ret = "error: SPAMBOX::MarkovChain - $e - BDB:$BerkeleyDB::Error";
            &main::mlog(0,$ret);
            delete $args{BDB};
            $@ = $e;
            return $ret;
        };
        return 'error: SPAMBOX::MarkovChain unknown exception - possible coding error'
            if (!ref$self||!$self->{simple}||!@{$self->{q}}||grep(/[A-Z]/o,@{$self->{q}}));
    } elsif ($args{File}) {
        my $file = $args{File};
        $self->{chains_file} = $file . '.chains';
        $self->{totals_file} = $file . '.totals';
        if (-e $self->{chains_file} && -e $self->{totals_file}) {
            eval{$self->{chains} = Storable::retrieve($self->{chains_file})} || return "error: HMM (Storable) - $self->{chains_file} - $@";
            eval{$self->{totals} = Storable::retrieve($self->{totals_file})} || return "error: HMM (Storable) - $self->{chains_file} - $@";
        } else {
            unlink $self->{chains_file};
            unlink $self->{totals_file};
        }
        $self->{simple} = exists $args{simple} ? $args{simple} : 3;
        delete $args{simple};
    } elsif ($args{HMMFile}) {
        if (-e $args{HMMFile}) {
            %{$self} = eval{%{Storable::retrieve($args{HMMFile})}};
            return "error: HMM (Storable) - $args{HMMFile} - $@" if $@;
        }
        $self->{HMMFile} = $args{HMMFile};
    }

    $self->{seperator} ||= $args{seperator} || $; ;
    delete $args{seperator};
    $self->{_symbols} ||= {};
    $self->{_recover_symbols} ||= $args{recover_symbols};
    delete $args{recover_symbols};
    $self->{chains} ||= {};
    $self->{totals} ||= {};
    $self->{top10} ||= {};
    delete $args{top10};
    $self->{top10count} ||= {};
    delete $args{top10count};
    $self->{nostarts} ||= $args{nostarts};
    delete $args{nostarts};
    if (! $self->{top}) {
        $self->{top} = $args{top} || 10;
        $self->{top}--;
    }
    delete $args{top};
    delete $self->{q};
    delete $args{q};
    if ($args{chains}) {
        return 'error: SPAMBOX::MarkovChain chains is not a HASH-reference'
          unless ref $args{chains} eq 'HASH';
        return 'error: SPAMBOX::MarkovChain totals is not a HASH-reference'
          unless ref $args{totals} eq 'HASH';

        $self->{chains} = $args{chains};
        $self->{totals} = $args{totals};
        delete $args{chains};
        delete $args{totals};
        $self->{simple} = 2;
    }
    foreach (keys %args) {$self->{$_} = $args{$_};}
    
    return ref $self ? $self : '';
}
