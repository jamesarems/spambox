#line 1 "sub main::BlackHeloOK"
package main; sub BlackHeloOK {
    my($fh,$fhelo)=@_;
    my $this=$Con{$fh};
    return 1 if $this->{BlackHeloOK};
    $this->{BlackHeloOK} = 1;
    return 1 if !$useHeloBlacklist;
    return BlackHeloOK_Run($fh,$fhelo);
}
