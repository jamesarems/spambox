#line 1 "sub main::headerAddrCheckOK"
package main; sub headerAddrCheckOK {
    my $fh = shift;
    my $this = $Con{$fh};
    d('headerAdrCheckOK');
    return 1 if skipCheck($this,'aa','ro');
    return headerAddrCheckOK_Run($fh);
}
