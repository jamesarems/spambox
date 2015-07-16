#line 1 "sub main::SPFok"
package main; sub SPFok {
    my $fh = shift;
    my $this = $Con{$fh};
    my $do1 = $CanUseSPF && $ValidateSPF;
    my $do2 = $CanUseSPF2 && $ValidateSPF && $SPF2;
    return 1 unless $do1 or $do2;
    return 0 unless SPFok_Run($fh);    # do SPF check on 'mail from'
    if (   $DoSPFinHeader
        && defined $this->{spfok}
        && ! $this->{error}
        && $this->{header} =~ /\nfrom:\s*($HeaderValueRe)/ois)   # and 'from:'
    {
        my $head = $1;
        headerUnwrap($head);
        if ($head =~ /($EmailAdrRe\@($EmailDomainRe))/o) {
            my $mf = $1;
            my $mfd = lc $2;
            my $envmfd;
            if ( $blockstrictSPFRe && $mf =~ /$blockstrictSPFReRE/ ) # ONLY if the 'from'  address is in strictSPFre
            {
        		 $envmfd = $1 if lc $this->{mailfrom} =~ /\@([^@]*)/o;
        		 return 1 if ($mfd eq $envmfd);
        		 mlog($fh,"SPF: do now the check for the header 'from: $mf' address") if $SPFLog;
        		 delete $this->{spfok};
        		 $this->{SPFokDone} = 0;
        		 my $omf = $this->{mailfrom};
        		 $this->{mailfrom} = $mf;
        		 my $ret = SPFok_Run($fh);
        		 $this->{mailfrom} = $omf;
        		 return 0 unless $ret;
            }
        }
    }
    return 0 if $fh && $DoDKIM && ! DMARCok($fh);
    return 1;
}
