#line 1 "sub main::return_cfg"
package main; sub return_cfg {
    my ($OU,%opts) = @_;
    my $RANDOM = $SSLPKPassword ? $SSLPKPassword : int(rand(1000)).'RAN'.int(rand(1000)).'DOM challenge password';
    my $outpass = $SSLPKPassword ? $SSLPKPassword : 'mypass';
    my $cfg = <<"EOT";
[ req ]
default_bits           = 1024
default_keyfile        = keyfile.pem
distinguished_name     = req_distinguished_name
attributes             = req_attributes
prompt                 = no
output_password        = $outpass

[ req_distinguished_name ]
C                      = $opts{C}
ST                     = $opts{ST}
L                      = $opts{L}
O                      = $opts{O}
OU                     = $OU
CN                     = $opts{CN}
emailAddress           = $opts{emailAddress}

[ req_attributes ]
challengePassword      = $RANDOM
EOT
    return $cfg;
}
