#line 1 "sub main::allNP"
package main; sub allNP {
    my $rcpt = shift;
    my $c = 0;
    for ( split( /\s+/o, $rcpt ) ) {
        return 0 unless matchSL( $_, 'noProcessing' );
        $c++;
    }
    return $c;
  }
