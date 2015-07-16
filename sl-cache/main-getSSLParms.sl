#line 1 "sub main::getSSLParms"
package main; sub getSSLParms {
    my %ssl;
    if (shift) {
        $ssl{SSL_server} = 1;
        $ssl{SSL_use_cert} = 1;
        $ssl{SSL_cert_file} = $SSLCertFile;
        $ssl{SSL_key_file} = $SSLKeyFile;
        $ssl{SSL_ca_file} = $SSLCaFile if $SSLCaFile;
        $ssl{SSL_passwd_cb} = \&getSSLPWD if getSSLPWD();
    }
    if ($SSL_cipher_list) {
        $ssl{SSL_cipher_list} = $SSL_cipher_list;
        $ssl{SSL_honor_cipher_order} = 1;
    }
    $ssl{SSL_verify_mode} = 0x00 ;
    $ssl{SSL_version} = $SSL_version if $SSL_version;
    $ssl{Timeout} = $SSLtimeout;

    return %ssl;
}
