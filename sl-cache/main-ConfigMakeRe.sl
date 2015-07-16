#line 1 "sub main::ConfigMakeRe"
package main; sub ConfigMakeRe {
    my ($name, $old, $new, $init, $desc)=@_;
    my $note = "AdminUpdate: $name changed from '$old' to '$new'";
    $note = "AdminUpdate: $name changed" if exists $cryptConfigVars{$name};
    mlog(0,$note) unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    $new = checkOptionList($new,$name,$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $ret = &ConfigRegisterGroupWatch(\$new,$name,$desc);
    $new =~ s/([\\]\|)*\|+/$1\|/go;
    $new = join('|', sort split(/\|/o,$new)) if $new;
    $new=~s/([\@\.\[\]\-\(\)\+\\])/\\$1/go;
    $new =~ s/\?/\./go;
    $new=~s/\*/\.\{0,64\}/go;
    $new||=$neverMatch; # regexp that never matches
    $ret .= ConfigShowError(1,"ERROR: !!!!!!!!!! missing MakeRE{$name} in code !!!!!!!!!!") if ! exists $MakeRE{$name} && $WorkerNumber == 0;

    $MakeRE{$name}->($new,$name);
    return $ret . ConfigShowError(1,$RegexError{$name});
}
