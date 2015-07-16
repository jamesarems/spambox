#line 1 "sub main::PEM_string2cert"
package main; sub PEM_string2cert {
    my $string = shift;
    my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem());
    Net::SSLeay::BIO_write($bio,$string);
    my $cert = Net::SSLeay::PEM_read_bio_X509($bio);
    Net::SSLeay::BIO_free($bio);
	Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error());
    return $cert;
}
