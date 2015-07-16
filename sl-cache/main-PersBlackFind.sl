#line 1 "sub main::PersBlackFind"
package main; sub PersBlackFind {
    my ($to, $from) = @_;
    d("PersBlackFind: $to, $from");
    $to = lc $to;
    $from = lc $from;
    return unless $to;
    return unless $from;
    return unless $PersBlackHasRecords;
    my ($domain) = $from =~ /^(?:$EmailAdrRe|\*)\@(?:\*|\*\.)?($EmailDomainRe)$/o;
    $domain =~ s/\s//go;
    return unless $domain;
    my @todomain = ($to);
    if ($to =~ /^(?:$EmailAdrRe|\*)\@(?:\*|\*\.)?($EmailDomainRe)$/o) {
        push (@todomain, $1);
        $todomain[0] =~ s/\s//go;
        my $dom = $todomain[0];
        push (@todomain, '@'.$dom);
        push (@todomain, '*@'.$dom);
    }
    my @subdom;
    my $d;
    for (reverse split(/\./o,$domain)) {
        if ($d) {
            $d = (scalar @subdom > 3)?"$_.$d":"$_$d";
            push @subdom, "*$d","\@*$d","*\@*$d","*.$d","*\@*.$d";
        } else {
            $d = ".$_";
            push @subdom, "*$d","\@*$d","*\@*$d";
        }
    }
    eval('$d=0;for(0...(unpack("A1",${\'X\'})-1)){++$d and (pop @subdom);}$d;') or return;
    my $found;
    for my $ts ($from,"\@$domain","*\@$domain","$domain",@subdom) {
        my $t = $ts;
        $t =~ s/\s//go;
        unless ($t) {
            for my $dom (@todomain) {
                delete $PersBlack{"$dom,$ts"};
                delete $PersBlack{"$dom,$t"};
            }
            next;
        }
        for my $dom (@todomain) {
            if (exists $PersBlack{"$dom,$ts"}) {
                $PersBlack{"$dom,$ts"} = time;
                $PersBlackHasRecords = 1;
                $found = $ts;
                my $ur = ($dom !~ /^$EmailAdrRe\@$EmailDomainRe$/io) ? ' unremoveable' : '';
                my $uw = ($ur && [caller(1)]->[3] =~ /PersBlackRemove/o) ? 'warning: ' : '';
                mlog(0,$uw."found$ur PersonalBlack entry '$dom,$ts'") if $ValidateSenderLog > 1 || $uw;
                last;
            }
        }
        last if $found;
    }
    return $found;
}
