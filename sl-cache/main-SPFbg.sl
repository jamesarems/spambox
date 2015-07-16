#line 1 "sub main::SPFbg"
package main; sub SPFbg {
    my $parm = shift;
    return unless ($ValidateSPF && $SPFCacheInterval && $SPFCacheObject && (($CanUseSPF2 && $SPF2) || $CanUseSPF));
    my $fh = time;
    ($Con{$fh}->{ip},$Con{$fh}->{mailfrom},$Con{$fh}->{helo}) = split(/ /o,$parm,3);
    $Con{$fh}->{max_dns_interactive_terms} = undef ;
    $Con{$fh}->{SPFlimits} = {
        max_name_lookups_per_term => undef,
        max_name_lookups_per_mx_mech => undef,
        max_name_lookups_per_ptr_mech  => undef,
        max_void_dns_lookups => undef,
    };
    SPFok_Run($fh);
    delete $Con{$fh};
}
