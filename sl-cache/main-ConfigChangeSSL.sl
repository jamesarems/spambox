#line 1 "sub main::ConfigChangeSSL"
package main; sub ConfigChangeSSL {
    my ( $name, $old, $new ,$init) = @_;

    if ($new ne $old) {
        $new =~ s/\\/\//go;
        $old =~ s/\\/\//go;
        $Config{$name} = ${$name} = $new;
        if (   (-f $new && -r $new)
            || $name eq 'SSLCaFile'
            || $name eq 'SSL_version'
            || $name eq 'SSL_cipher_list'
            || $name =~ /^(?:.+(?:SSLRequireClientCert|CertVerifyCB)|SSL(?:WEB|STAT|SMTP)Configure)$/o
        ) {
            mlog( 0, "AdminUpdate: $name changed from '$old' to '$new'" ) unless $init;
            if (-r $SSLCertFile and -r $SSLKeyFile and $AvailIOSocketSSL) {
                $CanUseIOSocketSSL = 1;
                if ($listenPortSSL) {
                    &ConfigChangeMailPortSSL('listenPortSSL','n/a',$listenPortSSL, 1);
                }
                if ($enableWebAdminSSL) {
                    &ConfigChangeAdminPort('webAdminPort','n/a',$webAdminPort, 1);
                }
                if ($enableWebStatSSL) {
                    &ConfigChangeStatPort('webStatPort','n/a',$webStatPort, 1);
                }
            }
            return '';
        } else {
            $Config{$name} = ${$name} = $old;
            mlog( 0, "AdminUpdate: $name not changed from '$old' to '$new' - file $new not found or unreadable" ) unless $init;
            return "<span class=\"negative\">file $new not found or unreadable</span>";
        }
    }
}
