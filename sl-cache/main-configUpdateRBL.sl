#line 1 "sub main::configUpdateRBL"
package main; sub configUpdateRBL {
    my ( $name, $old, $new, $init ) = @_;
    mlog( 0, "AdminUpdate: ValidateRBL updated from '$old' to '$new'" )
      unless $init || $new eq $old;
    $ValidateRBL = $Config{ValidateRBL} = $new;
    unless ($CanUseRBL) {
        mlog( 0, "AdminUpdate:error DNSBL disabled, Net::DNS not installed " )
          if $Config{ValidateRBL};
        ( $ValidateRBL, $Config{ValidateRBL} ) = 0;
        return '<span class="negative">*** Net::DNS must be installed before enabling DNSBL.</span>';
    } else {
        configUpdateRBLMH( 'RBLmaxhits', '', $Config{RBLmaxhits}, 'Cascading' );
    }
}
