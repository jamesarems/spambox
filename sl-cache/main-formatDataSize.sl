#line 1 "sub main::formatDataSize"
package main; sub formatDataSize {
    my ($size,$method)=@_;
    my ($res,$s);
    $res.=$s.'TB ' if $s=formatMethod($size,1099511627776,$method);
    $res.=$s.'GB ' if $s=formatMethod($size,1073741824,$method);
    $res.=$s.'MB ' if $s=formatMethod($size,1048576,$method);
    $res.=$s.'kB ' if $s=formatMethod($size,1024,$method);
    if ($size || !defined $res) {
        if ($method==0) {
            $res.=$size.'B ';
        } elsif ($method==1) {
            $res.=sprintf("%.1fB ",$size);
        }
    }
    $res=~s/\s$//o;
    return $res;
}
