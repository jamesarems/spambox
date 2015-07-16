#line 1 "sub main::canUserDo"
package main; sub canUserDo {
    my ($user,$what,$item) = @_;
    return 1 unless $adminusersdb;
    return 1 unless $user;
    return 1 if $user eq 'root';
    $item =~ s/\///go;
    my $key = "$user.$what.$item";
    return $WebIP{$ActWebSess}->{perm}->{$key} if $usedCrypt != 1 && exists $WebIP{$ActWebSess}->{perm}->{$key};
    unless (exists $AdminUsersRight{$key}) {
        return 1 if $usedCrypt == 1;
        return ($WebIP{$ActWebSess}->{perm}->{$key} = 1);
    }
    my $right = $AdminUsersRight{$key};
    if ($right !~ /refto\(([^\)]+)\)/o) {
        return 0 if $usedCrypt == 1;
        return ($WebIP{$ActWebSess}->{perm}->{$key} = 0);
    }
    my $key2 = "$1.$what.$item";
    unless (exists $AdminUsersRight{$key2}) {
        return 1 if $usedCrypt == 1;
        return ($WebIP{$ActWebSess}->{perm}->{$key} = 1);
    }
    return 0 if $usedCrypt == 1;
    return ($WebIP{$ActWebSess}->{perm}->{$key} = 0);
}
