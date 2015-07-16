#line 1 "sub main::setLDRE"
package main; sub setLDRE {
  SetRE('LDRE',"^(?:$_[0])\$",
        $regexMod,
        'Local Domains',$_[1]);
}
