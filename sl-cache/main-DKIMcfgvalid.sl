#line 1 "sub main::DKIMcfgvalid"
package main; sub DKIMcfgvalid {
    my %dkim = @_;
    my @domains;

    foreach my $domain (keys %dkim) {
        if ($domain !~ /($EmailDomainRe)/o) {
            mlog(0,"warning: DKIM-cfg - $domain is not a valid domain name - entry ignored") if $WorkerNumber == 0;
            delete $dkim{$domain};
            next;
        }
        foreach my $selector (keys %{$dkim{$domain}} ) {
            if ($selector !~ /^[a-zA-Z0-9_\-\.]+$/o) {
                mlog(0,"warning: DKIM-cfg - $selector for $domain is not a valid selector name - entry ignored") if $WorkerNumber == 0;
                delete $dkim{$domain}->{$selector};
                next;
            }
            if (! -e $dkim{$domain}->{$selector}{KeyFile}) {
                if ($dkim{$domain}->{$selector}{KeyFile}) {
                    mlog(0,"warning: DKIM-cfg - private key (KeyFile) $dkim{$domain}->{$selector}{KeyFile} in $selector for $domain not found - entry ignored") if $WorkerNumber == 0;
                    delete $dkim{$domain}->{$selector};
                    next;
                } else {
                    mlog(0,"warning: DKIM-cfg - private key (KeyFile) in $selector for $domain is not defined - entry ignored") if $WorkerNumber == 0;
                    delete $dkim{$domain}->{$selector};
                    next;
                }
            } else {
                my $key;
                eval{$key = Mail::DKIM::PrivateKey->load(File => $dkim{$domain}->{$selector}{KeyFile});};
                if ($@) {
                    mlog(0,"warning: DKIM-cfg - unable to load private key (KeyFile) $dkim{$domain}->{$selector}{KeyFile} in $selector for $domain - entry ignored - $@") if $WorkerNumber == 0;
                    delete $dkim{$domain}->{$selector};
                    next;
                }
            }
        }
        if (scalar(keys %{$dkim{$domain}})) {
            push @domains," $domain";
        } else {
            mlog(0,"warning: DKIM-cfg - no selectors for domain $domain left - entry ignored") if $WorkerNumber == 0;
            delete $dkim{$domain};
            next;
        }
    }
    return \%dkim,\@domains;
}
