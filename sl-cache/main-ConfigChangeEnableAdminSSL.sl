#line 1 "sub main::ConfigChangeEnableAdminSSL"
package main; sub ConfigChangeEnableAdminSSL {my ($name, $old, $new, $init)=@_;
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
            $enableWebAdminSSL = $Config{enableWebAdminSSL} = $new;
            return "<span class=\"negative\">Module IO::Socket::SSL is not installed</span>";
        }
    }
    my $usessln;
    my $usesslo;
    if ($new ne $old) {
        $usessln = $new ? 'HTTPS' : 'HTTP';
        $usesslo = $new ? 'HTTP' : 'HTTPS';
        $httpchanged = 1;
        mlog(0,"AdminUpdate: listening on admin port $usessln (changed from $usesslo)");
    }
    $enableWebAdminSSL = $Config{enableWebAdminSSL} = $new;
    &ConfigChangeAdminPort('webAdminPort', $webAdminPort, $webAdminPort,'renew');
    '';
}
