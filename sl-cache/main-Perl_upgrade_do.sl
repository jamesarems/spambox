#line 1 "sub main::Perl_upgrade_do"
package main; sub Perl_upgrade_do {
    my $upg_package = shift;
    my $touse;
    $ENV{HTTP_proxy} = 'http://'.$proxyserver if ( $proxyserver && ! $ENV{HTTP_proxy});
    $ENV{HTTP_proxy_user} = $proxyuser if ($proxyuser && ! $ENV{HTTP_proxy_user});
    $ENV{HTTP_proxy_pass} = $proxypass if ($proxypass && ! $ENV{HTTP_proxy_pass});
    eval('
    use ActivePerl::PPM::limited_inc;
    use ActivePerl::PPM::Client;
    use ActivePerl::PPM::Web qw(web_ua);
    use ActivePerl::PPM::Logger qw(ppm_log);
    use ActivePerl::PPM::Util qw(is_cpan_package clean_err join_with update_html_toc);
    $touse = \'Perl_PPM_upgrade_do\';
    $^O eq "MSWin32" && defined ${chr(ord(",") << 1)};
    ')
    or do {
#    mlog(0,"info: PPM ??? $@");
    eval('
    if($> != 0 && $^O ne "MSWin32") {
        mlog(0,"warning: SPAMBOX is not running as user root - skip CPAN Perl module update");
        return;
    }
    use CPAN;
    $touse = \'Perl_CPAN_upgrade_do\';
    defined ${chr(ord("\026") << 2)};
    ')} or do {
#    mlog(0,"info: CPAN ??? $@");
    return;
    };
    my @ret;
    @ret = $touse->($upg_package) if $touse;
    return wantarray ? @ret : $ret[0] ;
}
