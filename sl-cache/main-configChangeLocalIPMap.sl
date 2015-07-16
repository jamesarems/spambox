#line 1 "sub main::configChangeLocalIPMap"
package main; sub configChangeLocalIPMap {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new;
    $new = checkOptionList($new,$name,$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my ($hash) = $name =~ /^(smtp|http|dns|ldap)/oi;
    my $type = uc $hash;
    $hash = \%{$type.'_local_address'};
    %$hash = ();
    my $ret;
    for my $v (split(/\s*\|\s*/o,$new)) {
        my $v1 = $v;
        $v =~ s/\s//go;
        $v =~ s/\#.*//o;
        next unless $v;
        if ($v=~/^(.+)\=\>(.+)$/o) {
            my ($d,$l) = ($1,$2);
            $d .= '*' if $d !~ /^HostRe$|\*/o;
            if ($l =~ /^$IPRe$/i) {
                $hash->{$d} = $l;
                mlog(0,"info: local IP address for $type destination '$d' is '$l'") if $WorkerNumber == 0;
            } else {
                $ret .= ConfigShowError(0,"invalid local IP address definition '$l' in $name (line: $v1)");
            }
        } else {
            $ret .= ConfigShowError(0,"invalid syntax '$v1' is ignored for $name");
        }
    }
    return $ret;
}
