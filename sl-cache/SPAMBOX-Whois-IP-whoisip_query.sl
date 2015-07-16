#line 1 "sub SPAMBOX::Whois::IP::whoisip_query"
package SPAMBOX::Whois::IP; sub whoisip_query {
    my($ip, $timeout, $multiple_flag, $search_options) = @_;
    if($ip !~ /^$main::IPRe$/o) {
	    &main::mlog("error: whoisip_query - $ip is not a valid IP address");
        return;
    }
    $Timeout = $timeout || ($main::DNStimeout * ($main::DNSretry + 1)) || 10;
    my $response = eval{whoisip_lookup($ip,'ARIN',$multiple_flag,$search_options);};
    &main::mlog(0,"error: whoisip_query - $@") if $@;
    return (ref($response) eq 'HASH') ? $response : undef;
}
