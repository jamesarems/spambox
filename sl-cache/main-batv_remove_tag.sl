#line 1 "sub main::batv_remove_tag"
package main; sub batv_remove_tag {
    my ($fh,$mailfrom,$store) = @_;
    return $mailfrom if $mailfrom =~ /^SRS\d=/oi;
    return $mailfrom if $mailfrom =~ /^bounce-use=M=\d+=dr=/io;
    if ($mailfrom =~ /^[a-zA-Z0-9\-]{1,}=[a-zA-Z0-9\-]{1,}=($EmailAdrRe\@$EmailDomainRe)$/o) {
        $Con{$fh}->{$store} = $mailfrom if ($fh && $store);
        $mailfrom = $1;
    }
    return $mailfrom;
}
