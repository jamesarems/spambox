#line 1 "sub main::configUpdateCCD"
package main; sub configUpdateCCD {
    my ( $name, $old, $new, $init ) = @_;
    %ccdlist = ();
    mlog( 0, "AdminUpdate: $name updated from '$old' to '$new'" ) unless $init || $new eq $old;
    $ccSpamInDomain = $Config{ccSpamInDomain} = $new  unless $WorkerNumber;
    $new = checkOptionList( $new, 'ccSpamInDomain', $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    for my $adr ( split( /\|/o, $new ) ) {
            $ccdlist{lc $2} = $1 if ( $adr =~ /(\S*)\@(\S*)/o );
    }
    return '';
}
