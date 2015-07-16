#line 1 "sub main::SNMPgetUsers"
package main; sub SNMPgetUsers {
    my $users = 'root:root';
    foreach my $k (sort keys %AdminUsers) {
        next if $k =~ /^[~#]/o;
        $users .= "|$k:$k";
    }
    return $users;
}
