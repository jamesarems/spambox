#line 1 "sub main::BlackDomainOK"
package main; sub BlackDomainOK {
    my $fh = shift;
    my $this=$Con{$fh};
    my $tlit;

    return 1 if $this->{BlackDomainOK};
    $this->{BlackDomainOK} = 1;
    return 1 if !$DoBlackDomain;
    return BlackDomainOK_Run($fh);
}
