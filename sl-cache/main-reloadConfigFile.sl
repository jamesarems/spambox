#line 1 "sub main::reloadConfigFile"
package main; sub reloadConfigFile {

    # called on SIG HUP
    d('reloadConfigFile');
    my %newConfig = ();
    mlog(0,"reloading config");
    my $RCF;
    open($RCF,'<',"$base/spambox.cfg");
    while (<$RCF>) {
        s/\r|\n//go;
        s/^$UTFBOMRE//o;
        my ($k,$v) = split(/:=/o,$_,2);
        next unless $k;
        $newConfig{$k} = $v;
    }
    close $RCF;
    delete $newConfig{ConfigSavedOK};
    
    my $dec = ASSP::CRYPT->new($Config{webAdminPassword},0);

    foreach (keys %cryptConfigVars) {
        $newConfig{$_} = $dec->DECRYPT($newConfig{$_}) if ($newConfig{$_} =~ /^(?:[a-fA-F0-9]{2}){5,}$/o && defined $dec->DECRYPT($newConfig{$_})) ;
    }
    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
        my ($name,$nicename,$size,$func,$default,$valid,$onchange,$description)=@$c;
        if($Config{$name} ne $newConfig{$name}) {
            if($newConfig{$name}=~/$valid/i) {
                my $new=$1; my $info;
                if($onchange) {
                    $info=$onchange->($name,$Config{$name},$new);
                } else {
                    my $app; $app = "from '$Config{$name}' to '$new'" unless (exists $cryptConfigVars{$name});
                    mlog(0,"AdminUpdate: reload config - $name changed $app");
                    ${$name}=$new;

# -- this sets the variable name with the same name as the config key to the new value
# -- for example $Config{myName}="ASSP-nospam" -> $myName="ASSP-nospam";
                }
                if (exists $cryptConfigVars{$name} &&
                    $new =~ /^(?:[a-fA-F0-9]{2}){5,}$/o &&
                    defined $dec->DECRYPT($new)) {
                    
                    $Config{$name} = $dec->DECRYPT($new);
                    ${$name}=$Config{$name};
                } else {
                    $Config{$name}=$new;
                }
                &syncConfigDetect($name);
            } else {
                mlog(0,"AdminUpdate:error: invalid '$newConfig{$name}' -- not changed");
            }
        }
    }
    for my $idx (0...$#PossibleOptionFiles) {
        my $f = $PossibleOptionFiles[$idx];
        if($f->[0] ne 'asspCfg') {
            if (($Config{$f->[0]} =~ /^ *file: *(.+)/io && fileUpdated($1,$f->[0])) or
                 $Config{$f->[0]} !~ /^ *file: *(.+)/io)
            {
                $f->[2]->($f->[0],$Config{$f->[0]},$Config{$f->[0]},'',$f->[1]);
                &syncConfigDetect($f->[0]);
            }
        }
    }

    renderConfigHTML();
    $ConfigChanged = 1;
}
