#line 1 "sub main::SNMPVarType"
package main; sub SNMPVarType {
    my ($var,$sid,$asText) = @_;
    my $boolean = ($sid=~/^\.?1/o) ? $SNMPreturnBOOL : 'ASN_COUNTER';
#    my $ipaddr = ($sid=~/^\.?2/o) ? 'ASN_OCTET_STR' : 'ASN_IPADDRESS';
#    $$var =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/o and return $asText ? $ipaddr : $SNMPAS{$ipaddr};
    $$var =~ /^(?:0|1)$/o and return $asText ? $boolean : $SNMPAS{$boolean};
    $$var =~ /[^\d.]/o and return $asText ? 'ASN_OCTET_STR' : $SNMPAS{ASN_OCTET_STR};
    $$var =~ /\.[^.]*\./o and return $asText ? 'ASN_OCTET_STR' : $SNMPAS{ASN_OCTET_STR};
#    $$var =~ /\./o and return $asText ? 'ASN_FLOAT' : $SNMPAS{ASN_FLOAT};
    $$var =~ /^\d+$/o and return $asText ? 'ASN_COUNTER' : $SNMPAS{ASN_COUNTER};
    return $asText ? 'ASN_OCTET_STR' : $SNMPAS{ASN_OCTET_STR};
}
