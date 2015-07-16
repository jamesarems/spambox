#line 1 "sub main::BlockReportFormatAddr"
package main; sub BlockReportFormatAddr {
    return join('|', map {my $t = $_;
                          $t =~ s/([^*]+)\@/quotemeta($1).'@'/oe;
                          $t =~ s/\@([^*]+)/'@'.quotemeta($1)/oe;
                          $t =~ s/\@/\\@/;
                          $t =~ s/\*(\\\@)/$EmailAdrRe$1/o;
                          $t =~ s/\@\*/\@$EmailDomainRe/o;
                          $t;} @_);
}
