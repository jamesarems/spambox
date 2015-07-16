#line 1 "sub SPAMBOX::CryptTie::UNTIE"
package SPAMBOX::CryptTie; sub UNTIE {
 my ($obj,$count) = @_;
 &main::mlog(0, "error: untie attempted in SPAMBOX::CryptTie while $count inner references still exists") if $count;
}
