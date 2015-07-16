#line 1 "sub main::HeloIsGood"
package main; sub HeloIsGood {
    my($fh,$fhelo)=@_;
    return 1 unless $useHeloGoodlist;
    return 1 if !($HeloBlackObject);

    return HeloIsGood_Run($fh,$fhelo);
}
