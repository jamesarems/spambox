#line 1 "sub main::getChangedConfigValue"
package main; sub getChangedConfigValue {
    d('getChangedConfigValue');
    my @configs;
    {
        lock @changedConfig;
        threads->yield;
        @configs = @changedConfig;
        @changedConfig = ();
        threads->yield;
    }
    while (@configs) {
        my $line = shift @configs;
        $line =~ s/^\s+//o;
        $line =~ s/[\s\r\n]+$//o;
        my ($config,$value) = split(/\s*:=\s*/o,$line,2);
        if (exists $Config{$config}) {
            $ConfigChanged = changeConfigValue($config, $value) | $ConfigChanged;
        } elsif ($config =~ /^\&/o) {
            $line = $config.$value;
            my ($sub,$parm) = parseEval($line);
            if ($sub) {
                eval{$sub->($parm);};
                mlog(0,"error: running '$line' caused exception - $@") if ($@);
            } else {
                mlog(0,"error: unable to parse $line");
            }
        } else {
            my $old = $$config;
            $$config = $value;
            mlog(0,"info: internal variable '$config' changed from '$old' to '$value'");
        }
    }
}
