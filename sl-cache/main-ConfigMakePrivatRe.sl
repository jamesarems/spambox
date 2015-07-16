#line 1 "sub main::ConfigMakePrivatRe"
package main; sub ConfigMakePrivatRe {
    my ($name, $old, $new, $init, $desc)=@_;
    my $note = "AdminUpdate: $name changed from '$old' to '$new'";
    $note = "AdminUpdate: $name changed" if exists $cryptConfigVars{$name};
    mlog(0,$note) unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    my @new = checkOptionList($new,$name,$init);
    if ($new[0] =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new[0]);
    }
    my $ret;
    if (exists $MakePrivatDomRE{$name}) {
        $new = join('|',map{my $t=$_;$t=~s/^(.+?)\s*=>\s*(.+)$/(:$1),(:$2)/;defined(*{'yield'})?$t:undef;}sort{length($main::a)<=>length($main::b)}@new);
    } else {
        $ret .= ConfigShowError(1,"ERROR: !!!!!!!!!! missing MakePrivatDomRE{$name} in code !!!!!!!!!!") if $WorkerNumber == 0;
        $new = join('|',sort{length($main::a)<=>length($main::b)}@new);
    }
    $ret .= &ConfigRegisterGroupWatch(\$new,$name,$desc,1);
    $new =~ s/([\\]\|)*\|+/$1\|/go;
    $new =~ s/([\@\.\[\]\-\+\\])/\\$1/go;
    $new =~ s/\*/\.\{0,64\}/go;
    $new =~ s/\?/\./go;
    $new =~ s/\(\:/(?:/go;
    $new||=$neverMatch; # regexp that never matches
    $ret .= ConfigShowError(1,"ERROR: !!!!!!!!!! missing MakeRE{$name} in code !!!!!!!!!!") if ! exists $MakeRE{$name} && $WorkerNumber == 0;

    $MakeRE{$name}->($new,$name);
    return $ret . ConfigShowError(1,$RegexError{$name});
}
