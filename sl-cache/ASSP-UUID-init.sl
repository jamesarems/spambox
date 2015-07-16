#line 1 "sub ASSP::UUID::init"
package ASSP::UUID; sub init {
    $IS_UUID_STRING = qr/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/is;
    $IS_UUID_HEX    = qr/^[0-9a-f]{32}$/is;
    $IS_UUID_Base64 = qr/^[+\/0-9A-Za-z]{22}(?:==)?$/s;
}
