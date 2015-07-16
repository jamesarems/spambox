#line 1 "sub main::configChangeOC"
package main; sub configChangeOC {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: outbound charset conversion Table updated from '$old' to '$new'") unless $init || $new eq $old;
    $outChrSetConv=$new unless $WorkerNumber;
    $new = checkOptionList($new,'outChrSetConv',$init);
    if ($new =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new);
    }
    my $f;
    my $fa;
    my $t;
    my $ta;
    my $test="abc";
    my $error;
    for my $v (split(/\|/o,$new)) {
        $v=~/^(.*)\=\>(.*)$/o;
        $fa=$1;
        $ta=$2;
        eval{$f='';$f=Encode::resolve_alias(uc($fa));};
        eval{$t='';$t=Encode::resolve_alias(uc($ta));};
        if (! $f) {
            mlog(0,"error: codepage $fa is not supported by perl in outChrSetConv");
            $error .= "$fa ";
            next;
        }
        if (! $t) {
            mlog(0,"error: codepage $ta is not supported by perl in outChrSetConv");
            $error .= "$ta ";
            next;
        }
        eval{Encode::from_to($test,$f,$t)};
        if ($@) {
            mlog(0,"error: perl is unable to convert from characterset $f to $t in outChrSetConv - this conversion will be ignored");
            $error .= "$fa $ta ";
            next;
        } else {
            $outchrset{$f} = $t;
        }
    }
    $error = " - but error in $error - please check the log" if ($error);
    return $error;
}
