#line 1 "sub main::configUpdateURIBLMR"
package main; sub configUpdateURIBLMR {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: URIBL Maximum Replies updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    if ( $new < $URIBLmaxhits ) {
        mlog( 0, "AdminUpdate:error URIBL-Enable updated from '1' to '0': URIBLmaxreplies not >=  URIBLmaxhits" )
          if $Config{ValidateURIBL};
        ( $ValidateURIBL, $Config{ValidateURIBL} ) = 0;
        return
          '<span class="negative">*** URIBLmaxreplies must be more than or equal to URIBLmaxhits before enabling URIBL.</span>';
    } else {
        configUpdateURIBLSP( 'URIBLServiceProvider', '', $Config{URIBLServiceProvider}, 'Cascading' );
    }
}
