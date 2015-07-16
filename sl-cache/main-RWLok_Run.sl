#line 1 "sub main::RWLok_Run"
package main; sub RWLok_Run {
    my($fh,$ip)=@_;
    my $this=$Con{$fh};
    $fh = 0 if $fh =~ /^\d+$/o;
    d('RWLok');
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    return 1 unless $ip;
    return 1 if $this->{RWLokDone};
    $this->{RWLokDone} = 1;
    skipCheck($this,'sb','ro','wl','np','co','ispcip') && return 1;
    return 1 if $ip=~/$IPprivate/o;
    return 1 if ! $this->{ispip} && matchIP($this->{ip},'noRWL',$fh,0);
    return 1 if $this->{ispip} && $this->{cip} && matchIP($ip,'noRWL',$fh,0);
    return 1 if ( $this->{rwlok} % 2);
    $this->{rwlok} = RWLCacheFind($ip);
    if ( $this->{rwlok} % 2) {    # 1 (trust) or 3 (trust and whitelisted)
        $this->{nodamping} = 1;
        $this->{whitelisted} = 1 if $this->{rwlok} == 3 && $RWLwhitelisting;
        return 1 ;
    } elsif ($this->{rwlok} == 2) {   # RWLminhits not reached
        $this->{nodamping} = 1;
        $this->{rwlok} = '';
        return 0;
    } elsif ($this->{rwlok} == 4) {   # RWL none
        $this->{rwlok} = '';
        return 0;
    }
    $this->{rwlok} = '';
    return 1 if pbWhiteFind($ip) && !$RWLwhitelisting;
    my $trust;
    my ($rwls_returned,@listed_by,$rwl,$received_rwl,$time,$err);
    if (matchIP($ip,'noRWL',$fh,0)) {
        $this->{myheader}.="X-Assp-Received-RWL: lookup skipped (noRWL sender)\r\n" if $AddRWLHeader;
        return 1;
    }

    &sigoff(__LINE__);
    $rwl = eval{
        RBL->new(
            reuse       => ($DNSReuseSocket?'RBLobj':undef),
            lists       => [@rwllist],
            server      => \@nameservers,
            max_hits    => $RWLminhits,
            max_replies => $RWLmaxreplies,
            query_txt   => 0,
            max_time    => $RWLmaxtime,
            timeout     => 2,
            tolog       => $RWLLog>=2 || $DebugSPF
        );
    };
    # add exception check
    if ($@ || ! ref($rwl)) {
        &sigon(__LINE__);
        mlog($fh,"RWLok: error - $@" . ref($rwl) ? '' : " - $rwl");
        return;
    }
    my $lookup_return = eval{$rwl->lookup($ip,"RWL");};
    mlog($fh,"error: RWL check failed : $lookup_return") if ($lookup_return && $lookup_return ne 1);
    mlog($fh,"error: RWL lookup failed : $@") if ($@);
    my @listed=eval{$rwl->listed_by();};
    &sigon(__LINE__);
    return 0 if $lookup_return != 1;
    my $status;
    foreach (@listed) {
        if ($_ =~ /hostkarma\.junkemailfilter\.com/io && $rwl->{results}->{$_} !~ /127\.0\.\d+\.1/o) {
            next;
        } else {
            push @listed_by, $_;
        }
    }
    $rwls_returned=$#listed_by+1;
    if ($rwls_returned>=$RWLminhits) {
        $trust=2;
        my $ldo_trust;

        foreach (@listed_by) {
            my %categories = (
                      2 => 'Financial services',
                      3 => 'Email Service Providers',
                      4 => 'Organisations',
                      5 => 'Service/network providers',
                      6 => 'Personal/private servers',
                      7 => 'Travel/leisure industry',
                      8 => 'Public sector/governments',
                      9 => 'Media and Tech companies',
                     10 => 'some special cases',
                     11 => 'Education, academic',
                     12 => 'Healthcare',
                     13 => 'Manufacturing/Industrial',
                     14 => 'Retail/Wholesale/Services',
                     15 => 'Email Marketing Providers'
            );
            $received_rwl.="$_->". $rwl->{results}->{$_};
            if ($_ =~ /list\.dnswl\.org/io && $rwl->{results}->{$_} =~ /127\.\d+\.(\d+)\.(\d+)/o) {
                $ldo_trust = $2;
                $received_rwl.=",trust=$ldo_trust (category=$categories{$1});";
            } else {
                $received_rwl.="; ";
            }
        }
        $trust = $ldo_trust if ($ldo_trust > $trust or ($ldo_trust =~ /\d+/o && $rwls_returned == 1));
        $received_rwl.=") - high trust is $trust - client-ip=$ip";
        $received_rwl = "Received-RWL: ".(($trust>0)?"whitelisted ":' ')."from (" . $received_rwl;
        mlog($fh,$received_rwl,1) if $RWLLog;
        $this->{rwlok}=$trust if $trust>0;
        $this->{nodamping} = 1;
        pbBlackDelete($fh,$ip) if $fh;
        RBLCacheDelete($ip) if $fh;
        $this->{myheader}.="X-Assp-$received_rwl\015\012" if $AddRWLHeader;
        $this->{whitelisted}=1 if $trust>2 && $RWLwhitelisting;
        RWLCacheAdd($ip,($trust > 2) ? 3 : ($trust == 0) ? 2 : 1 ) ;
        $status = ($trust > 2) ? 3 : ($trust == 0) ? 2 : 1 ;
        pbWhiteAdd($fh,$ip,"RWL") if $trust>1 && $fh;
        return ($trust == 0) ? 0 : 1;
    } elsif ($rwls_returned>0) {
        $received_rwl="Received-RWL: listed from @listed_by; client-ip=$ip";
        mlog($fh,$received_rwl,1) if $RWLLog;
        $this->{nodamping} = 1;

        RWLCacheAdd($ip,2);
        $status = 2;
    } else {
        $received_rwl="Received-RWL: listed from none; client-ip=$ip";
        mlog($fh,$received_rwl,1) if $RWLLog>=2;

        RWLCacheAdd($ip,4);
        $status = 4;
    }
    if (! $fh) {
        $this->{messagereason} = $received_rwl;
        $this->{rwlstatus} = $status;
    }
    return 0;
}
