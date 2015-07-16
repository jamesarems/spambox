#line 1 "sub main::ConfigMakeIPRe"
package main; sub ConfigMakeIPRe {

    my ($name, $old, $new, $init, $desc)=@_;
    my $newexpanded;
    my $cips;
    use re 'eval';

    mlog(0,"AdminUpdate: $name changed from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $new unless $WorkerNumber;
    $new=~s/\s*\-\s*/\-/go;
    my @new = checkOptionList($new,$name,$init) ;
    if ($new[0] =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new[0]);
    }
    s/\|/\~/go for @new;    # all separators are now '~'
    $new = join('&',@new);  # all lines are now separated by '&'
    my $ret = &ConfigRegisterGroupWatch(\$new,$name,$desc,1);   # resolved groups have the '|' as separator
    $new =~ s/\|/\~/go;     # resolved groups have also now the '~' as separator
    @new = split('&',$new); # get each line again - we have to parse resolved groups at the left side of =>
    my @tnew;
    while (@new) {          # make a new entry for each group member at the left side of =>
        my ($iplist,$dom) = split(/\s*=>\s*/o,shift(@new));
        my @list = split(/\~/o,$iplist);
        if (@list == 1) {
            push @tnew , $iplist . ($dom ? "=>$dom" : '');
            next;
        } elsif (@list == 0) {
            next;
        }
        push(@tnew,$_.($dom?"=>$dom":'')) for @list;
    }
    $new = join('|',@tnew);

    my $loadRE;
    if (($WorkerNumber != 0) && ($loadRE = loadexportedRE($name))) {
         $loadRE =~ s/\)$//o if $loadRE =~ s/^\(\?(?:[xism\-]*)?\://o;
         eval{${$MakeIPRE{$name}}=qr/$loadRE/;};
         $ret .= ConfigShowError(0,"AdminInfo: regular expression error in '$name (exported):$loadRE' for $desc: $@") if $@;
         return $ret;
    }

    foreach my $l (split(/\|/o,$new)) {
        my $match;
        $l=~s/\.\./\./go;
        $l=~s/--+/*/go;
        $l=~s/\s*#.*//o;
        $l=~s/\s*;.*//o;
        $l=~s/\[([0-9a-f:]+)\]/$1/ig;
        ($l,$match) = split(/\s*\=\>\s*/o,$l,2);
        if ($match) {
            $match =~ s/([\\]\|)*\|+/$1\|/go;
            $match =~ s/([\@\.\[\]\-\+\\])/\\$1/go;
            $match =~ s/\*/\.\{0,64\}/go;
            $match =~ s/\?/\./go;
            $match = '(?:'.$match.')';
            my $tm = $match;
            $tm =~ s/\~/\|/go;  # make a real regex
            eval{my $f = qr/$tm/;};       # check the syntax
            if ($@) {
                $ret .= ConfigShowError(1,"AdminInfo: regular expression error in '$name' for $l=>$match: $@");
                next;
            }
            $match = '=>'.$match;
        }
        
        $l=~s/^\s*($IPRe)\s+($IPRe)/$1-$2/go;

        if ($CanUseCIDRlite && $l=~/^$IPRe-$IPRe/o ) {

            $l=~s/($IPRe)-($IPRe)(.*)/ipv6expand($1).'-'.ipv6expand($2)/oe;
            my $desc=$3;
            $desc =~ s/\s+/ /go;
            $desc =~ s/ $//o;
            $desc =~ s/^([^\s])/ $1/o if $desc;

            my $cidr = Net::CIDR::Lite->new;
            eval{$cidr->add_any($l);};
            if ($@) {
                $@=~/^(.+?)\sat\s/o ;
                $ret .= ConfigShowError(1,"AdminInfo: $name: $1 ($l)") ;
                next;
            }
            my @cidr_list = $cidr->list;
            my $cidr_join = join("$desc$match|",@cidr_list);
            $newexpanded.=$cidr_join."$desc$match|";
            next;
        } else {
            $newexpanded.=$l."$match|";
        }
    }
    $newexpanded=~s/\|$//o if $newexpanded;
    $new=$newexpanded;

    if ($new) {
        $ret .= replaceHostByIP(\$new,$name,$desc);
        $new =~ s/\|\|/\|/go;
    }

    if ($new) {
        my %ips = ();
        my %ip6s = ();
        my $new6;
        my $new4;
        foreach my $l (split(/\|/o,$new)) {
            my $hasIPv6;
            my $found;
            if ($l =~ /:[^:]*:/o) {
                $l =~ s/^\[([0-9a-f:\.]+)\]/$1/io;
                $found = $hasIPv6 = 1;
                my $ip;
                my $bits;
                my $ll = $l;
                my $desc;
                ($l, $desc) = ($l =~ m/^([0-9a-f:.]+(?:\/\d{1,3})?)\s*(.*)\s*$/io);
                $desc =~ s/\s+/ /go;
                $desc = " $desc" if ($desc);
                ($ip, $bits) = split(/\//o, $l);
                if ($l =~ /\//o) {
                    if (!$bits || $bits > 128) {
                        $ret .= ConfigShowError(1, "AdminInfo: invalid IPv6 Network Mask '/$bits' in $name line $l");
                        next;
                    }
                    $ip = ipv6expand($ip);
                } else {
                    my $tip = $ip = ipv6expand($ip);
                    $ip =~ s/(?::0)+$//o;
                    my @pre = split /:/o, $ip;
                    $bits = ($#pre+1)*16;
                    if ($bits > 128) {
                        $ret .= ConfigShowError(1, "AdminInfo: invalid IPv6 Address or Network Mask '/$bits' in $name line $l");
                        next;
                    }
                    $ip = $tip;
                }
                $ip6s{"$ip/$bits"} = "$ip/$bits$desc";
                $cips++;
                $l = $ll;
            }
            if (my @matches=$l=~/(\d{1,3}\.)(\d{1,3}\.?)?(\d{1,3}\.?)?(\d{1,3})?(\/)?(\d{1,2})?\s*(.*)\s*$/io)   {
                my $ip =              $1   .     $2     .     $3     .     $4;
                my $bits =                                                       $5 .     $6;
                my $nbits =                                                               $6;
                my $description =                                                                  $7;
                $description =~ s/\s+/ /go;
                $description = " $description" if ($description);
                $found = 1;
                
                foreach (@matches) {
                    $_ = 0 unless $_;
                    s/\.$//o;
                }
                if  ($matches[0]>255 || $matches[1]>255 || $matches[2]>255 || $matches[3]>255) {
                    $ret .= ConfigShowError(1,"AdminInfo: $name, error in line $l, IPv4 Dotted Quad Number > 255 ");
                    next;
                }

                $ip=~s/\.$//o;

                if ($hasIPv6) {
                    $nbits -= 96;
                    $nbits = 32 if $nbits < 0 || $nbits > 32;
                    $bits ||= '/' . $nbits;
                }

                if  ($nbits > 32) {
                    $ret .= ConfigShowError(1,"AdminInfo: $name, error in line $l, IPv4 Network Mask > 32 bit");
                    next;
                }

                my $dcnt = min(3,($ip=~tr/\.//));
                $ip .= '.0' x (3-$dcnt);
                if (! $nbits) {
                    $nbits = ++$dcnt * 8;
                    $bits = '/' . $nbits;
                }

                if  ("$ip$bits" !~ /^$IPv4Re\/\d{1,2}$/o) {
                    $ret .= ConfigShowError(1,"AdminInfo: $name error in line $l, IP notation: $ip$bits");
                    next;
                }
                $description =~ s/'/\\'/go;
                $ips{"$ip$bits"} = "$ip$bits$description";
                $cips++;
            }
            if (! $found) {
                $ret .= ConfigShowError(1,"AdminInfo: $name error in line $l - entry is invalid (no IP address or invalid network mask)");
            }
        }

        my $pr;
        my %tmpRE;
        $pr = 1 if (exists $MakePrivatIPRE{$name});
        if (scalar keys %ips) {
            my %tips = map {my $k = $_; my $t = $ips{$k}; if ($t =~ s/ \=\>(\(\?\:[^\)]+\))//o) {my $r = ${defined(*{'yield'})}; $r =~ s/\~/\|/go; $tmpRE{$k} = $r if $pr; };($k,$t);} keys %ips;
            eval{$new4 = create_iprange_regexp(4,\%tips);};
            $ret .= ConfigShowError(1,"AdminInfo:$name $@") if $@;
        }
        if (scalar keys %ip6s) {
            my %tip6s = map {my $k = $_; my $t = $ip6s{$k}; if ($t =~ s/ \=\>(\(\?\:[^\)]+\))//o) {my $r = ${defined(*{'yield'})}; $r =~ s/\~/\|/go; $tmpRE{$k} = $r if $pr; };($k,$t);} keys %ip6s;
            eval{$new6 = create_iprange_regexp(6,\%tip6s);};
            $ret .= ConfigShowError(1,"AdminInfo:$name $@") if $@;
        }
        %{$MakePrivatIPRE{$name}} = %tmpRE if $pr;

        if ($new6 && $new4) {
            $new4 =~ s/^.*\^(.*)\)/$1/o;
            $new6 =~ s/^.*\^(.*)\)/$1/o;
            $new = "(?msx-i:^($new6|$new4))";
        } elsif ($new6) {
            $new = $new6;
        } elsif ($new4) {
            $new = $new4;
        } else {
            $new = $neverMatch;    # regexp that never matches
        }

        $ret .= ConfigShowError(1,"ERROR: !!!!!!!!!! missing MakeIPRE{$name} in code !!!!!!!!!!") if ! exists $MakeIPRE{$name} && $WorkerNumber == 0;
        eval{${$MakeIPRE{$name}}=qr/$new/;};
        $ret .= ConfigShowError(1,"AdminInfo: regular expression error in '$name:$new': $@") if $@;
    } else {
        $new = $neverMatch; # regexp that never matches
        $ret .= ConfigShowError(1,"ERROR: !!!!!!!!!! missing MakeIPRE{$name} in code !!!!!!!!!!") if ! exists $MakeIPRE{$name} && $WorkerNumber == 0;
        eval{${$MakeIPRE{$name}}=qr/^(?:$new)/};
    }
    exportOptRE(\$new,$name) if $WorkerNumber == 0;
    return $ret;
}
