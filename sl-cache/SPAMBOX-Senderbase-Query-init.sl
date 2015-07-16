#line 1 "sub SPAMBOX::Senderbase::Query::init"
package SPAMBOX::Senderbase::Query; sub init {
    my $sep = shift;
    %keys = (
    0 => 'version_number',
    1 => 'org_name',
    2 => 'org_daily_magnitude',
    3 => 'org_monthly_magnitude',
    4 => 'org_id',
    5 => 'org_category',
    6 => 'org_first_message',
    7 => 'org_domains_count',
    8 => 'org_ip_controlled_count',
    9 => 'org_ip_used_count',
    10 => 'org_fortune_1000',             # Y -> OK

    20 => 'hostname',
    21 => 'domain_name',
    22 => 'hostname_matches_ip',
    23 => 'domain_daily_magnitude',
    24 => 'domain_monthly_magnitude',
    25 => 'domain_first_message',
    26 => 'domain_rating',               # AAA, AA, A, similar to credit rating services. or NR

    39 => 'senderbase',

    40 => 'ip_daily_magnitude',
    41 => 'ip_monthly_magnitude',
    43 => 'ip_average_magnitude',
    44 => 'ip_30_day_volume_percent',
    45 => 'ip_in_bonded_sender',         #  N, Y, or Y+ - Y+ = Bonded Sender Plus program
    46 => 'ip_cidr_range',
    47 => 'ip_blacklist_score',
    48 => 'ip_48',

    50 => 'ip_city',
    51 => 'ip_state',
    52 => 'ip_postal_code',
    53 => 'ip_country',
    54 => 'ip_longitude',
    55 => 'ip_latitude',
    
    99 => 'org'
    ) unless scalar keys(%keys);
    return $HOST if $HOST;
    map {$HOST.=$_.(join('',map{chr(46).$keys{$_};}qw(39 99))).$sep} qw(sa query);   # qw(query sa test)
    chop($HOST);
    return $HOST;
}
