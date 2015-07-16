#line 1 "sub main::matchIP"
package main; sub matchIP {
    my ( $ip, $re, $fhh, $donotmlog ) = @_;
    d("matchIP - $ip - $re",1);
    $lastREmatch = '';
    my $reRE = ${ $MakeIPRE{$re} };
    return 0 unless $ip && $reRE;
    return 0 if $reRE =~ /$neverMatchRE/o;

    $fhh = 0 if ! $fhh || ! exists $Con{$fhh};
    $ip =~ s/\r|\n//go;
    my $ret;
    local $^R = undef;
    use re 'eval';
    if ($ip =~ /:[^:]*:/o) {
        $ip =~ s/^\[([0-9a-f:]+)\].*/$1/io;
        my $ip6b = '6' . ipv6binary( ipv6expand($ip), 128);
        $ret = $^R if ($ip6b =~ /$reRE/xms);
    }
    if (!$ret && $ip =~ /($IPv4Re)$/o) {
        my $ip4 = $1;
        $ret = $^R if ('4'.unpack 'B32', pack 'C4', split(/\./xms, $ip4))=~/$reRE/xms;
    }
    $ret = 0 unless $ret;
	d("matchIP: OK ip=$ip re=$re") if $ret && ! $donotmlog;
    my $for;
    my @r;
    if ($fhh) {
        @r = keys %{$Con{$fhh}->{rcptlist}};
        @r = split(/ /o,$Con{$fhh}->{rcpt}) unless @r;
    }
    if (@r && $fhh && exists $MakePrivatIPRE{$re} && exists ${$MakePrivatIPRE{$re}}{$ret} && exists $Con{$fhh}) {
        my $f = ${$MakePrivatIPRE{$re}}{$ret};
        if (my $r = matchARRAY(qr/($f)/i,\@r)) {
            $for = " for $r";
            $lastREmatch = $r;
        } else {
            $ret = 0;
        }
    } elsif (exists $MakePrivatIPRE{$re} && exists ${$MakePrivatIPRE{$re}}{$ret}) {
        $ret = 0;
    }
    return $ret if $re eq 'noLog';
    $fhh = 0 if ($fhh =~ /^\d+$/o);
    my $alllog; $alllog = 1 if $allLogRe &&  $ip =~ /$allLogReRE/;
    if( ($fhh && ($alllog or (exists $Con{$fhh} && $Con{$fhh}->{alllog}))) or
        ($ret && !$donotmlog && $ipmatchLogging && ! matchIP( $ip, 'noLog',0,0 ) )
      )
    {
        my $matches = $ret ? 'matches': 'does not match';
        my $text = $ret ? "- with $ret$for" : '';
        mlog( $fhh, "IP $ip $matches $re $text", 1 )
    }
    return $ret;
}
