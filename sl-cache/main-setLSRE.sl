#line 1 "sub main::setLSRE"
package main; sub setLSRE {
  SetRE('LSRE',"^(?:$_[0])\$",
        $regexMod,
        'LocalHost',$_[1]);
}
