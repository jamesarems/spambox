#line 1 "sub main::getRes"
package main; sub getRes {
    my $run = shift;
    eval(<<'EOT');
    $run.='_v'.(unpack("A1",${'X'})+2);
    $_[0]->$run(! $CanUseIOSocketINET6 || $forceDNSv4);
EOT
    return;
}
