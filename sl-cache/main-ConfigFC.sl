#line 1 "sub main::ConfigFC"
package main; sub ConfigFC {
    my ( $href, $qsref ) = @_;

    if ($CanUseSPAMBOX_FC) {
        if (! ${'SPAMBOX_FC::TEST'}) {
            my $ret = eval{SPAMBOX_FC::process( $href, $qsref );};
            return ($@) ? $@ : $ret;
        } else {
            eval ('
            no SPAMBOX_FC;
            delete $INC{\'SPAMBOX_FC.pm\'};
            require SPAMBOX_FC;
            return SPAMBOX_FC::process( $href, $qsref );
            ');
            mlog(0,"warning: filecommander failed in test mode - $@") if $@;
        }
    } else {
        return  "HTTP/1.1 200 OK
Content-type: text/html

ERROR: lib/SPAMBOX_FC.pm is missing
";

    }
}
