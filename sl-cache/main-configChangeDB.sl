#line 1 "sub main::configChangeDB"
package main; sub configChangeDB {
    my ($name, $old, $new, $init)=@_;

    if ($name eq 'DBdriver' && $new) {
        if ($new =~ /^([a-z][a-z0-9\_\-]+)/oi) {
            my $driver = $1;
            if (! matchARRAY("^$driver\$",\@DBdriverNames)) {
                return "<span class=\"negative\"> - driver $driver is not available!</span>";
            }
        } else {
            return "<span class=\"negative\"> - wrong driver name in $new !</span>";
        }
    }
    if ($new =~ /^DB:.+$/o) {
        mlog(0,"AdminUpdate: $name not updated - wrong parameter $new - should be DB:");
        $Config{$name} = $old;
        $$name = $old;
        $qs{$name} = $old;
        return "<span class=\"negative\"> - wrong $new - write DB:  !</span>";
    }
    $Config{$name} = $$name = $qs{$name} = $new;
    $ConfigAdd{clearBerkeleyDBEnv} = 1 if $new ne $old; # clear Berkeley Env on next start
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless ($init || $new eq $old);
    return ConfigChangeDoPrivatSpamdb('DoPrivatSpamdb',$Config{DoPrivatSpamdb},$Config{DoPrivatSpamdb},undef) if $name eq 'spamdb';
    return '';
}
