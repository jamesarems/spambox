#line 1 "sub ASSP::CryptTie::UNTIE"
package ASSP::CryptTie; sub UNTIE {
 my ($obj,$count) = @_;
 &main::mlog(0, "error: untie attempted in ASSP::CryptTie while $count inner references still exists") if $count;
}
