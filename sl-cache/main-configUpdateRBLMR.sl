#line 1 "sub main::configUpdateRBLMR"
package main; sub configUpdateRBLMR {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: RBLmaxreplies updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    if ( $new < $RBLmaxhits ) {
        mlog( 0, "AdminUpdate:error DNSBL disabled, RBLmaxreplies not >= RBLmaxhits" )
          if $Config{ValidateRBL};
        ( $ValidateRBL, $Config{ValidateRBL} ) = 0;
        return
'<span class="negative">*** RBLmaxreplies must be >= RBLmaxhits before enabling DNSBL.</span>';
    } else {
        configUpdateRBLSP( 'RBLServiceProvider', '', $Config{RBLServiceProvider}, 'Cascading' );
    }
}
