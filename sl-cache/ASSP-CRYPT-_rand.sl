#line 1 "sub ASSP::CRYPT::_rand"
package ASSP::CRYPT; sub _rand {
	return int (((shift) / 100) * ((rand) * 100));
}
