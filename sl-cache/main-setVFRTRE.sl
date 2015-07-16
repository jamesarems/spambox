#line 1 "sub main::setVFRTRE"
package main; sub setVFRTRE {
    my $new=shift;
    $new||=$neverMatch; # regexp that never matches
    $new=~s/\*/\.\*/go;
    SetRE('VFRTRE',"^(?:$new)",
          $regexMod,
          'skip VRFY do RCPT TO',$_[0]);
}
