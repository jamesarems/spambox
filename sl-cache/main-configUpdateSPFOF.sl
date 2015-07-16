#line 1 "sub main::configUpdateSPFOF"
package main; sub configUpdateSPFOF {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name}=$Config{$name}=$new unless $WorkerNumber;
    $new = checkOptionList($new,$name,$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $spf = my $ret = '';
    foreach my $c (split(/\|/o,$new)) {
        if ($c=~/^\s*(\S+)\s*=>\s*(.*)?\s*$/o) {
            if (($CanUseSPF2 && eval{configUpdateSPFCheckRecord($1,$2)}) || ! $CanUseSPF2) {
                $spf.="'$1' => '$2',";
                mlog(0,"info: using SPFRecord '$2' for domain '$1' in $name") if ( $WorkerNumber == 0 && ($MaintenanceLog >= 2 or $DebugSPF));
            } else {
                mlog(0,"error: SPF record in \"$c\" is not valid - $@") if $WorkerNumber == 0;
                $ret .= "<span class=\"negative\">error: SPF record in \"$c\" for $name is not valid - $@</span><br />";
            }
        } elsif ($SPFlocalRecord) {
            $spf.="'$c' => '$SPFlocalRecord'," ;
            mlog(0,"info: using SPFlocalRecord for domain $c in $name") if ( $WorkerNumber == 0 && ($MaintenanceLog >= 2 or $DebugSPF));
        }
    }
    $spf=~s/,$//o;
    $name = lc $name;
    ${$name} = $spf;
    return $ret;
}
