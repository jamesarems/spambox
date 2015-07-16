#line 1 "sub main::configUpdateRBLMH"
package main; sub configUpdateRBLMH {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: RBLmaxhits updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    if ( $new <= 0 ) {
        mlog( 0,
"AdminUpdate:error DNSBL disabled', RBLmaxhits must be > 0 before enabling DNSBL.</span>';"
        ) if $Config{ValidateRBL};
        ( $ValidateRBL, $Config{ValidateRBL} ) = 0;
        return '<span class="negative">*** RBLmaxhits must be > 0 before enabling DNSBL.</span>';
    } else {
        configUpdateRBLMR( 'RBLmaxreplies', '', $Config{RBLmaxreplies}, 'Cascading' );
    }
}
