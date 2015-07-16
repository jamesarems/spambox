#line 1 "sub main::ConfigChangePassPhrase"
package main; sub ConfigChangePassPhrase {my ($name, $old, $new, $init)=@_;

    # change the Password
    if (!$init) {
        $Config{adminusersdbpass}=$adminusersdbpass=$new;
        if ($adminusersdb) {
            putAdminUsers($adminusersdbpass);
            mlog(0,"AdminUpdate: AdminUsersDB PasswPhrase changed - adminusersdb rewritten") if $usedCrypt != -1;
        } else {
            mlog(0,"AdminUpdate: AdminUsersDB PasswPhrase changed") if $usedCrypt != -1;
        }
        return '';
    }
}
