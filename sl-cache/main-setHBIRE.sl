#line 1 "sub main::setHBIRE"
package main; sub setHBIRE {
  SetRE('HBIRE',"^(?:$_[0])\$",
        $regexMod,
        'HELO Blacklisted Ignore',$_[1]);
}
