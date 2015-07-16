#line 1 "sub main::configChangeProxy"
package main; sub configChangeProxy {
 my ($name, $old, $new, $init)=@_;

 if (! $init && $WorkerNumber == 0) {
  while (my ($k,$v) = each(%Proxy)) {
    unpoll($ProxySocket{$k},$readable);
    unpoll($ProxySocket{$k},$writable);
    eval{close($ProxySocket{$k});};
    mlog(0,"proxy listening on $k was closed");
   }
   %Proxy = ();
  }

 mlog(0,"AdminUpdate: Proxy Table updated from '$old' to '$new'") unless $init || $new eq $old;
 $ProxyConf=$Config{ProxyConf}=$new unless $WorkerNumber;
 $new = checkOptionList($new,'ProxyConf',$init);
 if ($new =~ s/^\x00\xff //o) {
     ${$name} = $Config{$name} = $old;
     return ConfigShowError(1,$new);
 }
 my $k;
 for my $v (split(/\|/o,$new)) {
     $v=~/^(.*?)\=\>(.*)$/o;
     $Proxy{$1}=$2;
 }
 if (! $init && $WorkerNumber == 0) {
  while (my ($k,$v) = each(%Proxy)) {
        my ($to,$allow) = split(/<=/o, $v);
        $allow = " allowed for $allow" if ($allow);
        my ($ProxySocket,$dummy) = newListen($k,\&ConToThread,2);
        $ProxySocket{$k} = shift @$ProxySocket;
        for (@$dummy) {s/:::/\[::\]:/o;}
        mlog(0,"proxy started: listening on @$dummy forwarded to $to$allow");
  }
 }
 return;
}
