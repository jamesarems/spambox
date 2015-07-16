#line 1 "sub main::BackSctrCheckOK"
package main; sub BackSctrCheckOK {
    my ($fh,$ip) = @_;
    d('BackSctrCheckOK');
    my $this = $Con{$fh};
    my $chip;
    my @reason;
    my $lvl;
    
    return 1 if $this->{backsctrdone};
    $this->{backsctrdone} = 1;
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};

    return 1 unless $CanUseDNS;
    return 1 unless $BackSctrServiceProvider;
    return 1 if !$DoBackSctr;
    return 1 if ! $this->{isbounce};
    skipCheck($this,'co','sb','ro') && return 1;
    return 1 if ($this->{whitelisted} && !$BackWL);
    return 1 if (($this->{noprocessing} & 1) && !$BackNP);
    return 1 if &matchIP($ip,'noBackSctrIP',$fh,0);
    return 1 if (&matchSL([$this->{rcpt},$this->{mailfrom}],'noBackSctrAddresses'));
    if ($noBackSctrRe && $this->{header} =~ /(noBackSctrReRE)/) {
       mlogRe($fh,($1||$2),'noBackSctrRe','nobackscatter');
       return 1;
    }
    my $tlit = &tlit($DoBackSctr);

    my $backcache = &BackDNSCacheFind($ip);
    d('BackDNSCacheFind - cache - ' . $backcache);
    @reason = &BackSctrDNS($fh,$ip) if ($backcache == 0);
    d("BackSctrDNS - reason - @reason");

    if ($backcache == 2 or (! @reason && $backcache == 0)) {
        my $txt = $backcache ? ' [cache]' : '';
        mlog($fh,"$tlit Backscatter detection OK$txt") if $BacksctrLog >= 2;
        d("BackDNSCacheAdd - $ip - 2");
        &BackDNSCacheAdd($ip,2);
        d('BackSctrCheckOK - OK');
        return 1;
    }

    if ($backcache == 0) {
        d("BackDNSCacheAdd - $ip - 1");
        &BackDNSCacheAdd($ip,1);
    } else {
        push @reason, "[CACHE] $BackSctrServiceProvider";
    }

    d('BackSctrCheckOK - failed');

    $this->{messagereason}="IP: $ip is listed by ".join(',',@reason);

    mlog($fh,"$tlit $this->{messagereason}") if $BacksctrLog;
    return 1 if ($DoBackSctr == 2 or $DoBackSctr == 4);
    pbWhiteDelete($fh,$ip);
    pbAdd($fh,$ip,'backsctrValencePB','Backscatter-failed');
    $Stats{msgBackscatterErrors}++;
    return 1 if $DoBackSctr==3;
    if ($Back250OKISP && ($this->{ispip} || $this->{cip})) {
        $this->{accBackISPIP} = 1;
        mlog($fh,"info: force sending 250 OK to ISP for failed bounced message") if $BacksctrLog;
        return 1;
    } else {
        $this->{prepend}="[Backscatter]";
        thisIsSpam($fh,$this->{messagereason},$BackLog,"554 5.7.9 $this->{messagereason}",$DoBackSctr==4,0,1);
        return 0;
    }
}
