#line 1 "sub SPAMBOX::Whois::IP::whoisip_lookup"
package SPAMBOX::Whois::IP; sub whoisip_lookup {
    my($ip,$registrar,$multiple_flag,$search_options) = @_;
    my $extraflag = 1;
    my $oip = $ip;
    my $whois_response;
    my $whois_response_hash;
    my @whois_response_array;
    while($extraflag) {
        last unless $registrar && $ip;
        if ($main::nextPossibleWHOISQuery{$registrar} > time) {
            &main::mlog(0,"warning: WHOIS lookups on '$registrar' are skipped until ".&main::timestring($main::nextPossibleWHOISQuery{$registrar},'','')) if ($main::DebugSPF || $main::SenderBaseLog);
            undef $whois_response_hash;
            undef $whois_response;
            @whois_response_array = ();
            last;
        }
        my $lookup_host = $whois_servers{$registrar};
        $ip = $oip if $ip =~ /^\!/o && $registrar ne 'ARIN';
        &main::mlog(0,"info: whoisip_lookup '$ip' on '$registrar' => '$lookup_host'") if $main::DebugSPF || $main::SenderBaseLog >= 2;
    	($whois_response,$whois_response_hash) = whoisip_do_query($lookup_host,$ip,$multiple_flag);
        push(@whois_response_array,$whois_response_hash);
    	my($new_ip,$new_registrar) = whoisip_processing($whois_response,$registrar,$ip,$whois_response_hash,$search_options);
        if(($new_ip ne $ip) || ($new_registrar ne $registrar) ) {
    	    $ip = $new_ip;
    	    $registrar = $new_registrar;
    	    next;
    	}else{
    	    undef $extraflag;
    	}
    }

    if($whois_response_hash) {
        return wantarray ? ($whois_response_hash,\@whois_response_array) : $whois_response_hash ;
    }else{
        return wantarray ? ($whois_response,\@whois_response_array) : $whois_response ;
    }
}
