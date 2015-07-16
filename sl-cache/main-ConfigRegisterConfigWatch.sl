#line 1 "sub main::ConfigRegisterConfigWatch"
package main; sub ConfigRegisterConfigWatch {
    my ($name,$sub,$time,$desc) = @_;
    $ConfigWatch{$name} = "$sub,$time,$desc";
    d("registered config watch for $name with '$ConfigWatch{$name}'");
    my $minwait = 999999999;
    my $ret;
    while (my($k,$v) = each %ConfigWatch) {
        if (!$k || !$v) {
            delete $ConfigWatch{$k};
            next;
        }
        next if $v eq 'delete';
        my ($s,$t,$d) = split(/,/o,$v,3);
        $t ||= 0;
        if ($t < 60) {
            $ret .= ConfigShowError(1,"error: config reload scheduler got a value of $t seconds (less 60) for $name - ignored");
            delete $ConfigWatch{$k};
            next;
        }
        $minwait = $t if $t < $minwait;
    }
    if ($WorkerNumber == 0) {
        $NextConfigReload = time + $minwait;
        $ret .= ConfigShowError(0,"info: next automatic configuration reload is scheduled at ".timestring($NextConfigReload)) if $minwait < 999999999;
    }
    return $ret;
}
