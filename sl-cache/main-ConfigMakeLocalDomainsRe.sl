#line 1 "sub main::ConfigMakeLocalDomainsRe"
package main; sub ConfigMakeLocalDomainsRe {
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
    my $mHostPortRe = $HostRe . '(?:\:' . $PortRe . ')?' . '(?:,' . $HostRe . '(?:\:' . $PortRe . ')?)*';

    my %toChangeMTA;
    $new = join('|', sort split(/\|/o,$new)) if $new;
    my @entry = split(/\|/o,$new);
    $new = '';
    my $ld;
    my $mta;
    my $defaultMTA;
    %DomainVRFYMTA = ();
    while (@entry) {
       my $ad = shift @entry;
       $ad =~ s/\s//go;
       ($ld,$mta) = split(/\s*\=\>\s*/o,$ad,2);
       if ($ld =~ /^(all)$/io && $mta) {
           my $e = $1;
           if ($mta !~ /$mHostPortRe/o) {
               $ret .= ConfigShowError(0,"warning: localDomains - VRFY entry '$ad' contains a not valid MTA definition")
                   if $WorkerNumber == 0;
               next;
           }
           $ret .= ConfigShowError(0,"warning: localDomains - duplicate VRFY entry '$e' found - '$ad' will be used")
               if $defaultMTA && $WorkerNumber == 0;
           $defaultMTA = $mta;
           next;
       }
       if ($ld =~ /^all$/io) {
           $ret .= ConfigShowError(0,"warning: localDomains - VRFY entry '$ad' contains no MTA definition")
               if $WorkerNumber == 0;
           next;
       }
       if ($mta && $mta =~ /$mHostPortRe/o) {
           $DomainVRFYMTA{lc $ld} = $mta;
           $ret .= ConfigShowError(0,"warning: localDomains VRFY entry $ld also exists in LocalAddresses_Flat")
               if &matchHashKey('FlatVRFYMTA', lc $ld ) && $WorkerNumber == 0;
       } elsif ($mta && $mta !~ /$mHostPortRe/o) {
           $ret .= ConfigShowError(0,"warning: found entry '$ad' with wrong syntax in localDomains file") if $WorkerNumber == 0;
           next;
       }
       $toChangeMTA{lc $ld} = 1 if $ld && ! exists $DomainVRFYMTA{lc $ld};
       $ld=~s/([\.\[\]\-\(\)\+\\])/\\$1/go;
       $ld =~ s/\?/\./go;
       $ld=~s/\*/\.\{0,64\}/go;
       if ( ! $ld ) {
           $ret .= ConfigShowError(0,"warning: found wrong entry '$ad' in localDomains file") if $WorkerNumber == 0;
           next;
       }
       $new .= $ld.'|';
    }
    if ($defaultMTA) {
        while (my ($k,$v) = each %toChangeMTA) {
            $DomainVRFYMTA{$k} = $defaultMTA if ! exists $DomainVRFYMTA{$k};
        }
    }
    mlog(0,"info: enabled VRFY for domain(s) ". join(' , ', keys %DomainVRFYMTA)) if scalar keys %DomainVRFYMTA && $WorkerNumber == 0;
    chop($new);
    $new||=$neverMatch; # regexp that never matches
    $ret .= ConfigShowError(1,"ERROR: !!!!!!!!!! missing MakeRE{$name} in code !!!!!!!!!!") if ! exists $MakeRE{$name} && $WorkerNumber == 0;
    $MakeRE{$name}->($new,$name);
    return $ret . ConfigShowError(1,$RegexError{$name});
}
