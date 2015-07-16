#line 1 "sub main::configUpdateStringToNum"
package main; sub configUpdateStringToNum {
    my ( $name, $old, $new, $init , $desc) = @_;
    mlog( 0, "AdminUpdate: $name updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    $new = checkOptionList( $new, $name, $init );
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my %hash = (
                 'MaxEqualXHeader' => 'MEXH'
               );
    my $hash = $hash{$name};
    my $ret;

    my @templist = split( /\|/o, $new );

    my %tmp = ();
    while (@templist) {
        my $c = shift @templist;
        $c =~ s/^\s+//o;
        $c =~ s/\s+$//o;
        my ($tag,$val) = $c =~ /^(.+?)\s*\=\>\s*(\d+)$/o;
        next unless $tag;
        next unless $val;
        $tmp{$tag} = $val;
    }
    %{$hash} = %tmp;
    return $ret;
}
