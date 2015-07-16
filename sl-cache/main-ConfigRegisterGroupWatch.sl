#line 1 "sub main::ConfigRegisterGroupWatch"
package main; sub ConfigRegisterGroupWatch {
    my ($new,$name,$note,$action) = @_;
    my $ret;
    $action = $action ? 0 : 1;
    foreach my $group (keys %GroupWatch) {
        delete $GroupWatch{$group}->{$name};
        delete $GroupWatch{$group} unless (scalar keys %{$GroupWatch{$group}});
    }
    my $re = '\[\s*([A-Za-z0-9.\-_]+)\s*\]';
    $re .= '([^\|]*)' if $action;
    while (${$new} =~ s/$re/&GroupReplace($GroupRE{$1},$2)/e) {
        d("RegisterGroup: found group '$1' in '$name' with extension '$2' (action is $action) - replaced with '$GroupRE{$1}'") if $WorkerNumber == 0;
        $GroupWatch{$1}->{$name} = [[caller(unpack("A1",${'X'})-1)]->[unpack("A1",${'X'})+1]];
        $note and push (@{$GroupWatch{$1}->{$name}} , $note);
        if (! exists $GroupRE{$1} && $WorkerNumber == 0) {
            $ret .= ConfigShowError(0,"warning: found group definition [$1] in configuration for $name - but group $1 is not defined or empty in Groups");
        }
    }
    return $ret;
}
