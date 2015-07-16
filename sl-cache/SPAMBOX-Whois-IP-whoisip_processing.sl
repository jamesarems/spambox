#line 1 "sub SPAMBOX::Whois::IP::whoisip_processing"
package SPAMBOX::Whois::IP; sub whoisip_processing {
    my($response,$registrar,$ip,$hash_response,$search_options) = @_;

#Response to comment.
#Bug report stating the search method will work better with different options.  Easy way to do it now.
#this way a reference to an array can be passed in, the defaults will still
#be TechPhone and OrgTechPhone
    my $pattern1 = 'techphone';
    my $pattern2 = 'orgtechphone';
    if(($search_options) && ($search_options->[0] ne '') ) {
    	$pattern1 = $search_options->[0];
    	$pattern2 = $search_options->[1];
    }

    foreach (@{$response}) {       # we reached the query limit for a WHOIS provider;
        if (/(access(?:.*?)(?:denied|limit reached))/io) {
            &main::mlog(0,"warning: got <$1> Answer from WHOIS registrar $registrar - WHOIS queries to WHOIS registrar $registrar are now disabled for the next 6 hours");
            $main::nextPossibleWHOISQuery{$registrar} = 6 * 3600 + time;
            die "WHOIS registrar $registrar told us: $1\n";
        }
    }
    
    foreach (@{$response}) {       # is there a redirect to another whois database?
      	if (   /Contact information can be found in the (\S+)\s+database/io
            || /This network has been transferred to (\S+)/io
            || /in the (\S+) whois database/io
           )
        {
            $registrar = $1;
            &main::mlog(0,"info: '$registrar' told us to lookup information for '$ip' on '$1'") if $main::DebugSPF || $main::SenderBaseLog >= 2;
            return($ip,$registrar);
    	} elsif ((/OrgID:\s+(\S+)/io) || (/source:\s+(\S+)/io) && (!defined($hash_response->{$pattern1})) ) {
    	    my $val = $1;
    	    if($val =~ /^(?:RIPE|APNIC|KRNIC|LACNIC|AFRINIC)$/o) {
                &main::mlog(0,"info: '$registrar' redirect to lookup information for '$ip' on '$val'") if ($main::DebugSPF  || $main::SenderBaseLog >= 2) && $registrar ne $val;
                $registrar = $val;
                return($ip,$registrar);
    	    }
    	}
    }

    foreach (@{$response}) {    # is there a force to change the queried IP
    	if (/Parent:\s+(\S+)/io) {
    	    if($1 && (!defined($hash_response->{'techphone'})) && (!defined($hash_response->{$pattern2})) ) {
                my $l = $1;
                &main::mlog(0,"info: '$registrar' told us to lookup information for Parent '$l' instead of '$ip'") if $main::DebugSPF || $main::SenderBaseLog >= 2;
                $ip = $l;
        		last;
    	    }
        } elsif ($registrar eq 'ARIN' && ($_ !~ /.+\:.+/o) && (/.+\((.+)\).+$/o) ) {
            my $l = $1;
            if ($l =~ /\d{1,3}\-\d{1,3}\-\d{1,3}\-\d{1,3}/o){
    	        &main::mlog(0,"info: '$registrar' told us to lookup information for '! $l' instead of '$ip'") if $main::DebugSPF || $main::SenderBaseLog >= 2;
                $ip = '! '.$l;
    	    }
    	} else {
    	    $ip = $ip;
    	    $registrar = $registrar;
    	}
    }
    return($ip,$registrar);
}
