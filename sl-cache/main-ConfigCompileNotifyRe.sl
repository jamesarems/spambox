#line 1 "sub main::ConfigCompileNotifyRe"
package main; sub ConfigCompileNotifyRe {
    my ($name, $old, $new, $init)=@_;
    my $note = "AdminUpdate: $name changed from '$old' to '$new'";
    $note = "AdminUpdate: $name changed" if exists $cryptConfigVars{$name};
    mlog(0,$note) unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    $new = checkOptionList($new,$name,$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }

    if ($new) {
        %NotifyRE = ();
        %NotifySub = ();
        my @entry = split(/\|/o,$new);
        while (@entry) {
            my $e = shift(@entry);
            my ($re,$adr,$sub) = split(/\=\>/o,$e);
            $NotifySub{$re} = $sub if $sub;
            $adr ||= $Notify;
            if ($adr) {
                my %address;
                map {$address{lc $_} = $_;} split(/\s*,\s*/o,$adr);  # make recipient unique
                $adr = join(',', values %address);
                if (exists $NotifyRE{$re}) {        # the same regex was seen before
                    $NotifyRE{$re} .= ",$adr";
                } else {
                    $NotifyRE{$re} = $adr;
                }
            }
        }
        $new = ( keys %NotifyRE) ? join('|', keys %NotifyRE) : undef;
    }
    $new ||= $neverMatch; # regexp that never matches
    
    SetRE($name.'RE',$new,'is',$name);
    return ConfigShowError(1,$RegexError{$name});
}
