#line 1 "sub SPAMBOX::CRYPT::_rand"
package SPAMBOX::CRYPT; sub _rand {
	return int (((shift) / 100) * ((rand) * 100));
}
