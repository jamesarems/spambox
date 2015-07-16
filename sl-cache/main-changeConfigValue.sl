#line 1 "sub main::changeConfigValue"
package main; sub changeConfigValue {
    my ($config, $value) = @_;
    d("changeConfigValue - $config");
    if (! $config || ! exists $Config{$config}) {
        mlog(0,"error: scheduled configuration change request for $config - $config is not a valid configuration parameter name");
        return;
    }
    my $ret;
    mlog(0,"info: scheduled configuration change request for $config");
    $qs{$config} = $value;
    $ActWebSess = 'Config_Schedule'.Time::HiRes::time();
    $WebIP{$ActWebSess}->{user} = 'root';
    my $error = checkUpdate($ConfigArray[$ConfigNum{$config}]->[0],$ConfigArray[$ConfigNum{$config}]->[5],$ConfigArray[$ConfigNum{$config}]->[6],$ConfigArray[$ConfigNum{$config}]->[1]);
    if ($error =~ /span class.+?negative/o) {
        $error =~ s/<b>(.+?)<\/b>/$1/o;
        mlog(0,"info: scheduled configuration change request failed for - $config - $error");
    } elsif ($error =~ /span class.+?positive/o) {
        my $text = (exists $cryptConfigVars{$config}) ? '' : " to ". $qs{$config};
        mlog(0,"info: changed config for - $config$text");
        $ret = 1;
    } else {
        mlog(0,"info: config unchanged - $config - ". $qs{$config});
    }
    delete $qs{$config};
    return $ret;
}
