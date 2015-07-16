#line 1 "sub main::checkSMIME"
package main; sub checkSMIME {
    my $mime = ${$_[0]};
    my $addr = lc $_[1];

    my $result = { 'isSigned' => 0,
                   'verified' => 0,
                 };
    return $result if(! $addr || ! $mime || ! eval("use Crypt::SMIME 0.15 ();1;"));

    my $addrRE = qr/^\Q$addr\E$/i;
    my $smime = Crypt::SMIME->new();
    $result->{isSigned} = $smime->isSigned($mime);
    return $result if(! $result->{isSigned} || $smime->isEncrypted($mime));
    if (! $emailIntSMIMEpubKeyPath) {
        mlog(0,"info: SMIME: public key folder missing");
        return $result;
    }
    my $key = "$emailIntSMIMEpubKeyPath/$addr.pem";
    eval{$smime->setPublicKey($key);};
    if ($@) {
        mlog(0,"info: SMIME: can't set the public Key for signature check ($addr) - $@");
        return $result;
    }

    my @signerAddress;
    eval{$smime->check($mime)};
# Verification failure  23016:error:21071065:PKCS7 routines:PKCS7_signatureVerify:digest -> mail altered
# Verification failure   9544:error:21075075:PKCS7 routines:PKCS7_verify:certificate verify -> cert not verified
# Verification failure   6192:error:21075069:PKCS7 routines:PKCS7_verify:signature failure -> wrong signature
    if ($@) {
        $@ =~ s/ at sub .+$//o;
        mlog(0,"info: SMIME: signature check failed - $@");
        @signerAddress = eval{ map {my $str = lc Net::SSLeay::X509_NAME_print_ex(Net::SSLeay::X509_get_subject_name(PEM_string2cert($_))); my ($ret) = $str =~ /emailaddress=($EmailAdrRe\@$EmailDomainRe)/o; $ret;} @{Crypt::SMIME::getSigners($mime)}; };
        if ($@) {
            mlog(0,"info: SMIME: can't get signer information - (@signerAddress) - $@");
        } else {
            mlog(0,"info: SMIME: this report request was signed by @signerAddress");
        }
        ${$_[0]} = undef;
        return $result;
    }
    @signerAddress = eval{ map {my $str = lc Net::SSLeay::X509_NAME_print_ex(Net::SSLeay::X509_get_subject_name(PEM_string2cert($_))); my ($ret) = $str =~ /emailaddress=($EmailAdrRe\@$EmailDomainRe)/o; $ret;} @{Crypt::SMIME::getSigners($mime)}; };
    if ($@) {
        mlog(0,"error: SMIME: can't get signer information - (@signerAddress) - $@");
    } else {
        mlog(0,"info: SMIME: this report request was signed by @signerAddress");
    }
    $result->{verified} = matchARRAY($addrRE,\@signerAddress);
    return $result;
}
