#line 1 "sub main::URIBLok"
package main; sub URIBLok {
    my ( $fh, $bd, $thisip,$done ) = @_;
    my $this = $Con{$fh};
    return 1 if !$TLDSRE;
    return 1 if !$CanUseURIBL;
    my $ValidateURIBL = $ValidateURIBL;    # copy the global to local - using local from this point
    if ($this->{overwritedo}) {
        $ValidateURIBL = $this->{overwritedo};   # overwrite requ by Plugin
        delete $this->{uribldone};
    }
    return 1 if $this->{uribldone};
    $this->{uribldone} = 1;
    return 1 if !$ValidateURIBL;

    return URIBLok_Run($fh, $bd, $thisip, $done);
}
