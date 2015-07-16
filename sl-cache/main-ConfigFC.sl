#line 1 "sub main::ConfigFC"
package main; sub ConfigFC {
    my ( $href, $qsref ) = @_;

    if ($CanUseASSP_FC) {
        if (! ${'ASSP_FC::TEST'}) {
            my $ret = eval{ASSP_FC::process( $href, $qsref );};
            return ($@) ? $@ : $ret;
        } else {
            eval ('
            no ASSP_FC;
            delete $INC{\'ASSP_FC.pm\'};
            require ASSP_FC;
            return ASSP_FC::process( $href, $qsref );
            ');
            mlog(0,"warning: filecommander failed in test mode - $@") if $@;
        }
    } else {
        return  "HTTP/1.1 200 OK
Content-type: text/html

ERROR: lib/ASSP_FC.pm is missing
";

    }
}
