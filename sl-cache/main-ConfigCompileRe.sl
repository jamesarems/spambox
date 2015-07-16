#line 1 "sub main::ConfigCompileRe"
package main; sub ConfigCompileRe {
    my ($name, $old, $new, $init)=@_;
    my $note = "AdminUpdate: $name changed from '$old' to '$new'";
    $note = "AdminUpdate: $name changed" if exists $cryptConfigVars{$name};
    mlog(0,$note) unless $init || $new eq $old;
    my $orgnew = $new;
    $Config{$name} = ${$name} = $new unless $WorkerNumber;
    my $error;
    $new = checkOptionList($new,$name,$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    if ($name eq "MyCountryCodeRe" && !$new && $localhostip && $localhostip !~ /$IPprivate/o) {
        $new = SenderBaseMyIP($localhostip);
        mlog(0,"warning: MyCountryCodeRe is currently not configured") unless $WorkerNumber;
        mlog(0,"info: MyCountryCodeRe is now set to '$new' - resolved by SenderBase") unless $WorkerNumber;
        ${$name} = $Config{$name} = $new if ($WorkerNumber == 0 && $orgnew !~ /^\s*file\s*:/io);
    }

# only grouping (no capturing) allowed inside regexes: (aa) -> (?:aa)
    my $hasChanged;

    if ($WorkerNumber == 0) {
        $hasChanged = $new =~ s/((?<!\\))\(([^\?\\][^:]?)/$1(?:$2/go
            if $RegexGroupingOnly && $new !~ /a(?:ssp)?\\?-do?\\?-n(?:ot)?\\?-o(?:ptimize)?\\?-r(?:egex)?\|?/io;
        unicodeNormalizeRe(\$new,$name);
        $RegExStore{$name} = $new;
    } else {
        $new = $RegExStore{$name};
    }
    
    if (exists $WeightedRe{$name}) {
        my $defaultHow;
        $defaultHow = $1 if $new =~ s/\s*!!!\s*([nNwWlLiI\+\-\s]+)?\s*!!!\s*\|?//o;
        $defaultHow =~ s/\s//go;
        $defaultHow =~ s/\++/+/go;
        $defaultHow =~ s/\-+/-/go;
        $WeightedReOverwrite{$name} = 0;
        my @Weight = @{$name.'Weight'};
        my @WeightRE = @{$name.'WeightRE'};
        @{$name.'Weight'} = ();
        @{$name.'WeightRE'} = ();
        while ($new =~ s/(\~([^\~]+)?\~|([^\|]+)?)\s*\=\>\s*([+\-]?(?:0?\.\d+|\d+\.\d+|\d+))?(?:\s*\:\>\s*([nNwWlLiI\+\-\s]+)?)?/$2$3/o) {
            my $re = ($2?$2:'').($3?$3:'');
            my ($we,$how) = ($4,$5);
            $we = 1 if (!$we && $we != 0);
            $we += 0;
            $re =~ s/(([^\\]?)\$\{\$([a-z][a-z0-9]+)\})/(defined ${$3}) ? $2.${$3} : $1/oige if $AllowInternalsInRegex;
            $how =~ s/\s//go;
            $how =~ s/\++/+/go;
            $how =~ s/\-+/-/go;
            $how ||= $defaultHow;

            eval{$note =~ /$re/};
            if ($@) {
                $RegexError{$name} = 'error in regular expression';
                mlog(0,"error: weighted regex for $name is invalid '$re=>$we' - $@") if $WorkerNumber == 0;
                $error .= "error: weighted regex for $name is invalid '$re=>$we'<br />";
                mlog(0,"warning: value for $name was not changed - all changes are ignored") if $WorkerNumber == 0;
                @{$name.'Weight'} = @Weight;
                @{$name.'WeightRE'} = @WeightRE;
                $new = $old;
                if (! $RegexGroupingOnly) {
                    return "<span class=\"negative\"> - weighted regex for $name is invalid '$re=>$we'!</span>";
                } else {
                    $RegexGroupingOnly = 0;
                    mlog(0,"info: try to use unoptimized regex $name") if $WorkerNumber == 0;
                    my $ret = &ConfigCompileRe($name, $old, $orgnew, $init);
                    $RegexGroupingOnly = 1;
                    return $ret;
                }
            } else {
                delete $RegexError{$name};
            }
            if ($name =~ /bomb|script|black/o && $how) {
                if ($how =~ /[nN][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 1;
                }
                if ($how =~ /[wW][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 2;
                }
                if ($how =~ /[lL][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 4;
                }
                if ($how =~ /[iI][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 8;
                }
            } elsif ($name =~ /Reversed/o && $how) {
                if ($how =~ /[nN][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 1;
                }
                if ($how =~ /[wW][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 2;
                }
            } elsif ($name =~ /Helo/o && $how) {
                if ($how =~ /[nN][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 1;
                }
                if ($how =~ /[wW][^\-]?/o) {
                    $WeightedReOverwrite{$name} |= 2;
                }
            }
            push (@{$name.'WeightRE'},'{'.$how.'}'.$re);
            push (@{$name.'Weight'},$we);
        }
        my $count = 0;
        foreach my $k (@{$name.'Weight'}) {
            my $reg = ${$name.'WeightRE'}[$count];
            my $how; $how = $1 if $reg =~ s/^\{([^\}]*)?\}(.+)$/$2/o;
            $reg =~ s/^\<\<\<(.*?)\>\>\>$/$1/go;
            strip50($reg);
            $how = " for [$how]" if $how;
            mlog(0,"info: $name : regex $reg - weight set to $k$how") if $WorkerNumber == 0 && $MaintenanceLog >= 2;
            $count++;
        }
        mlog(0,"info: Regex $name: $count weighted regular expression defined") if $count && $WorkerNumber == 0 && $MaintenanceLog;
    }

    if ($name eq 'TLDS') {
        if ($CanUseRegexpOptimizer && $new) {
         my $loadRE;
         if (($WorkerNumber != 0) && ($loadRE = &loadexportedRE($name))) {
             $loadRE =~ s/\)$//o if $loadRE =~ s/^\(\?(?:[xims\-\^]*)?\://o;
             $TLDSRE = qr/$loadRE/;
         } else {
            $new .= '|'.$punyRE;
            my $lenBefore = length($new) + 4 + 9;      # (?-xims:(?:......))
            my $o;
            eval{
                $o = $optReModule->new;
#                $o->set(debug => $debug);
                $TLDSRE = $o->optimize(qr/(?i:$new)/);
            };
            if ($@) {
                mlog(0,"warning: regex optimization failed for '<$name>' - $@ - try using unoptimized regex") if $WorkerNumber == 0;
                $error .= "warning: regex optimization failed for '<$name>' - $@ - try using unoptimized regex<br />";
                use re 'eval';
                $TLDSRE = qr/(?i:$new)/;
            } else {
                my $lenAfter = length $TLDSRE;
                mlog(0,"info: optimized regex for '<$name>' - length in byte before: $lenBefore - after: $lenAfter") if $MaintenanceLog >= 2 && $WorkerNumber == 0;;
            }
            exportOptRE(\$TLDSRE,'TLDS') if $WorkerNumber == 0;
          }
        } else {
            use re 'eval';
            $TLDSRE = qr/(?i:$new)/;
        }
        if (! $new) {
            mlog(0,"warning: no top level domain file ($Config{TLDS}) found - URIBL check will be skipped") if $WorkerNumber == 0 && $ValidateURIBL;
            $error .= "warning: no top level domain file ($Config{TLDS}) found - URIBL check will be skipped<br />" if $ValidateURIBL;
        }
    } else {
        $new||=$neverMatch; # regexp that never matches

        # replace something like ${$EmailDomainRe} with the value of $EmailDomainRe
        $new =~ s/(([^\\]?)\$\{\$([a-z][a-z0-9]+)\})/(defined ${$3}) ? $2.${$3} : $1/oige if $AllowInternalsInRegex;

        if ($RegexGroupingOnly) {
            if (! SetRE($name.'RE',$new,'is',$name, $name ,$hasChanged) ) {
                $RegexError{$name} = 'error in regular expression';
                $RegexGroupingOnly = 0;
                @{$name.'WeightRE'} = ();
                @{$name.'Weight'}   = ();
                mlog(0,"info: try to use unoptimized regex $name") if $WorkerNumber == 0;
                $error .= "info: try to use unoptimized regex $name<br />";
                $error .= &ConfigCompileRe($name, $old, $orgnew, $init);
                $RegexGroupingOnly = 1;
            } else {
                delete $RegexError{$name};
            }
        } else {
            if (! SetRE($name.'RE',$new,'is',$name,$name)) {
                $RegexError{$name} = 'error in regular expression';
                $error .= "regex for $name is invalid!<br />";
            } else {
                delete $RegexError{$name};
            }
        }
    }
    if ($error) {
        $error =~ s/<\/?span[^>]*>//go;
        $error = "<span class=\"negative\">$error</span>";
    }
    return $error;
}
