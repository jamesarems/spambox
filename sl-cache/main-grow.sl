#line 1 "sub main::grow"
package main; sub grow
{
    return unless eval {require Convert::Scalar;};
    Convert::Scalar::grow(${$_[0]},$_[1]);
    return;
}
