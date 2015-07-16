#line 1 "sub main::ConfigChangeEnableStatSSL"
package main; sub ConfigChangeEnableStatSSL {my ($name, $old, $new, $init)=@_;
    if ($new) {
        if (! -e $SSLCertFile) {
            $new = $old = 0;
            $enableWebAdminSSL = $new;
            $Config{enableWebAdminSSL} = $new;
            return "<span class=\"negative\">Couldn't find file $base/certs/server-cert.pem</span>";
        }
        if (! -e $SSLKeyFile) {
            $new = $old = 0;
            $enableWebAdminSSL = $new;
            $Config{enableWebAdminSSL} = $new;
            return "<span class=\"negative\">Couldn't find file $base/certs/server-key.pem</span>";
        }
        if (! $CanUseIOSocketSSL) {
            $new = $old = 0;
            $enableWebAdminSSL = $new;
            $Config{enableWebAdminSSL} = $new;
            return "<span class=\"negative\">Module IO::Socket::SSL is not installed</span>";
        }
    }
    if ($new ne $old) {
        my $usessln = $new ? 'HTTPS' : 'HTTP';
        my $usesslo = $new ? 'HTTP' : 'HTTPS';
        mlog(0,"AdminUpdate: listening on stat port $usessln (changed from $usesslo)");
    }
    $enableWebStatSSL = $Config{enableWebStatSSL} = $new;
    &ConfigChangeStatPort('webStatPort', $webStatPort, $webStatPort,'renew');
}
