#line 1 "sub main::configUpdateURIBLMH"
package main; sub configUpdateURIBLMH {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: URIBL Maximum Hits updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    if ( $new <= 0 ) {
        mlog( 0, "AdminUpdate:error URIBL-Enable updated from '1' to '0', URIBLmaxhits not > 0" )
          if $Config{ValidateURIBL};
        ( $ValidateURIBL, $Config{ValidateURIBL} ) = 0;
        return '<span class="negative">*** URIBLmaxhits must be defined and positive before enabling URIBL.</span>';
    } else {
        configUpdateURIBLMR( 'URIBLmaxreplies', '', $Config{URIBLmaxreplies}, 'Cascading' );
    }
}
