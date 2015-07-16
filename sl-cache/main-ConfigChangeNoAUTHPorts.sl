#line 1 "sub main::ConfigChangeNoAUTHPorts"
package main; sub ConfigChangeNoAUTHPorts {my ($name, $old, $new, $init)=@_;
    return '' if $new eq $old && ! $init;

    $$name = $Config{$name} = $new unless $WorkerNumber;
    mlog(0,"AdminUpdate: $name changed to $new from $old") if $WorkerNumber == 0 && ! $init;
    my $listen = 'lsnNoAUTH';
    fillPortArray($listen, $new);
    return '';
}
