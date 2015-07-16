#line 1 "sub main::putAdminUsers"
package main; sub putAdminUsers {
    my $pass = shift;
    my %temphash = ();
    my $bin;

    if (! $mysqlSlaveMode) {
      %temphash = %AdminUsers;
      %AdminUsers = ();
    }
    $bin = $AdminUsersObject->{BIN};
    $AdminUsersObject->{enc} = ($usedCrypt == -1) ? ASSP::CRYPT->new($pass,$bin,1) : ASSP::CRYPT->new($pass,$bin);
    $AdminUsersObject->{dec} = ASSP::CRYPT->new($pass,$bin);
    if (! $mysqlSlaveMode) {
        %AdminUsers = %temphash;
        eval{$AdminUsersObject->flush();};
    }

    if (! $mysqlSlaveMode) {
        %temphash = %AdminUsersRight;
        %AdminUsersRight = ();
    }
    $bin = $AdminUsersRightObject->{BIN};
    $AdminUsersRightObject->{enc} = ($usedCrypt == -1) ? ASSP::CRYPT->new($pass,$bin,1) : ASSP::CRYPT->new($pass,$bin);
    $AdminUsersRightObject->{dec} = ASSP::CRYPT->new($pass,$bin);
    if (! $mysqlSlaveMode) {
        %AdminUsersRight = %temphash;
        eval{$AdminUsersRightObject->flush();};
    }
}
