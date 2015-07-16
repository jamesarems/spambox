#line 1 "sub main::configUpdateSPFLR"
package main; sub configUpdateSPFLR {
    my ($name, $old, $new, $init)=@_;
    ${$name}=$Config{$name}=$new;
    my $ret;
    my $rec = ($new && $CanUseSPF2) ? eval{configUpdateSPFCheckRecord('nospam.org',$new)} : '';
    if (($new && $rec) || ! $new || ! $CanUseSPF2) {
        mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
    } elsif ($new && !$rec && $CanUseSPF2) {
        ${$name}=$Config{$name}=$old;
        mlog(0,"error: SPF record \"$new\" is not valid - $@") if $WorkerNumber == 0;
        return "<span class=\"negative\">error: SPF record \"$new\" for $name is not valid - $@</span><br />";
    }
    if ($new ne $old && $name eq 'SPFlocalRecord') {
        $ret .= configUpdateSPFOF('SPFoverride','',$SPFoverride,1);
        $ret .= configUpdateSPFOF('SPFfallback','',$SPFfallback,1);
    }
    return $ret;
}
