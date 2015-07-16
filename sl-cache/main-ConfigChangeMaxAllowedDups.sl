#line 1 "sub main::ConfigChangeMaxAllowedDups"
package main; sub ConfigChangeMaxAllowedDups {
    my ($name, $old, $new, $init)=@_;
    return if $WorkerNumber != 0 && $init ne 'reread';
    my $count = -1;
    if ($new && $Config{UseSubjectsAsMaillogNames} && $Config{discarded} && $Config{spamlog}) {
        if ($WorkerNumber == 0) {
            cmdToThread('fillSpamfiles','');
        } else {
            $count = &fillSpamfiles();
        }
    } else {
       %Spamfiles = ();
       %SpamfileNames = ();
    }
    mlog(0,"AdminUpdate: $name from '$old' to '$new'") unless $init || $new eq $old;
    mlog(0,"info: $name - ".nN($count)." files registered in $Config{spamlog} folder") if $init && $new && $count > -1;
    $Config{$name} = $$name = $new unless $WorkerNumber;
}
