#line 1 "sub main::configUpdateMaxSize"
package main; sub configUpdateMaxSize {
    my ( $name, $old, $new, $init , $desc) = @_;
    mlog( 0, "AdminUpdate: $name updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    my %hash = (
                 'MaxRealSizeAdr' => 'MRSadr',
                 'MaxSizeAdr' => 'MSadr',
                 'MaxRealSizeExternalAdr' => 'MRSEadr',
                 'MaxSizeExternalAdr' => 'MSEadr'
               );
    my $hash = $hash{$name};
    $new = checkOptionList( $new, $name, $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $ret = &ConfigRegisterGroupWatch(\$new,$name,$desc);

    my @templist = split( /\|/o, $new );

    my %tmp = ();
    while (@templist) {
        my $c = shift @templist;
        $c =~ s/\s//go;
        my ($adr,$val) = $c =~ /^(.+?)\=\>(\d+)$/o;
        next unless $adr;
        next unless defined $val;
        if ($adr =~ /^\@[^@]+$/o) {                         # a domain
            $adr = '[^@]+'.$adr;
            $adr = '^(?i:'.$adr.')$';
        } elsif ($adr =~ /^[^@]+\@$/o) {                 # a user name with @
            $adr = $adr.'[^@]+';
            $adr = '^(?i:'.$adr.')$';
        } elsif ($adr =~ /^(?:\d{1,3}\.[\d\.\*\?]+|[a-f0-9:\?\*]+)$/io) {    # an IP address
            $adr = '^(?i:'.$adr.')';
        } elsif ($adr !~ /\@/o) {                        # a simple user name
            $adr = $adr.'@[^@]+';
            $adr = '^(?i:'.$adr.')$';
        } elsif ($adr =~ /^[^@]+\@[^@]+$/) {             # an email address
            $adr = '^(?i:'.$adr.')$';
        } else {
            next;
        }
        $adr =~ s/([^\\]?)\@/$1\\@/go;
        $tmp{$adr} = $val;
    }
    %{$hash} = %tmp;
    return $ret;
}
