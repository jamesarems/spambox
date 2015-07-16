#line 1 "sub main::GPBSetup"
package main; sub GPBSetup {
    $GPBmodTestList = sub {my ($how,$parm,$whattodo,$text,$value,$skipbackup)=@_;
    d("GPBmodTestList - $parm - $whattodo");
    my $file;
    my $GPBFILE;
    my @cont;
    my $case = (exists $preMakeRE{$parm}) ? '' : 'i';
    $case = 'i' if $parm eq 'preHeaderRe';
    if(${$parm} =~ /^\s*file:\s*(.+)\s*$/io) {
        $file=$1;
    } else {
        mlog(0,"warning: config parameter '$parm' is not configured to use a file (file:...) - unable to $whattodo entry");
        return 0;
    }
    $file="$base/$file" if $file!~/^(([a-z]:)?[\/\\]|\Q$base\E)/io;
    return if ( !-e "$file");
    (open ($GPBFILE, '<',$file)) or (mlog(0,"error: unable to read from file $file for '$parm' to '$whattodo' entry") and return 0);
    @cont = <$GPBFILE>;
    close ($GPBFILE);
    my $hasNetIP;
    my $run = sub {
        my $s1 = NetAddr::IP::Lite->new(shift,(unpack("A1",${chr(ord("\026") << 2)})-1))+(shift);
        $s1 =~ s :/.*::o;
        return ipv6compress($s1);
    };
    my $cidr_list = sub {
        return unless $CanUseCIDRlite;
        my $cidr = Net::CIDR::Lite->new;
        $cidr->add_any(shift);
        return map {my $t = $_; $t =~ s/^(.*?)(\/\d+)?$/Net::CIDR::Lite::_compress_ipv6($1).$2/oe; $t;} $cidr->list;
    };
    if (   $whattodo eq 'delete'
        && (   grep(/(?$case:^\s*[^#]?\s*\Q$value\E)/,@cont)
            || (exists $MakeIPRE{$parm} && $value =~ /^$IPRe(?:\/\d+)?$/o && ($hasNetIP = $CanUseNetAddrIPLite && $CanUseNetIP))
           )
       )
    {
        my $ret = 0;
        if (!$skipbackup) {
            unlink "$file.bak";
            rename("$file","$file.bak");
        }
        (open ($GPBFILE, '>',"$file")) or (mlog(0,"error: unable to write to file $file for '$parm' to '$whattodo' entry") and return 0);
        binmode $GPBFILE;
        my $valIP;
        my $valIsIP = $value =~ /^$IPRe(?:\/\d+)?$/o;
        mlog(0,"warning: to remove an IP-address or IP-address-range from a defined IP-address-range, you need to install the modules Net::IP and NetAddr::IP::Lite") if (!$hasNetIP && exists $MakeIPRE{$parm} && $valIsIP);
        while (@cont) {
            my $line = shift @cont;
            $line =~ s/\r?\n$//o;
            if ($line =~ /(?$case:^\Q$value\E)/) {
                mlog(0,"$how: $value deleted from $parm - $text");
                $ret = 1;
                next;
            }
            eval {
            if ($hasNetIP && exists $MakeIPRE{$parm} && $valIsIP && $line !~ /^\s*[;#]/o) {
                $valIP ||= eval{Net::IP->new($value)};
                if ($valIP) {
                    my ($iline,$desc) = $line =~ /^\s*([^#]+)(#.*)?$/o;
                    $iline =~ s/\s+$//o;
                    if ($iline =~ /^($IPv6Re)(?:\/(\d+)|-($IPv6Re))?/o) {
                        my $ip1 = ipv6expand($1);
                        my $bits = $2;
                        my $ip2 = $3?ipv6expand($3):undef;
                        if (! $bits && ! $ip2) {
                            my $tip = $ip1;
                            $tip =~ s/(?::0)+$//o;
                            my @pre = split /:/o, $tip;
                            $bits = ($#pre+1)*16;
                        }
                        $iline = $ip1 . ($bits?"/$bits":'') . ($ip2?"-$ip2":'');
                    } elsif ($iline =~ /^(\d{1,3}\.?(?:\d{1,3}\.?){0,3})\/?(\d{1,2})?$/o) {
                        my $ip = $1;
                        my $bits = $2;
                        $ip=~s/\.$//o;
                        my $dcnt = min(3,($ip=~tr/\.//));
                        $ip .= '.0' x (3-$dcnt);
                        $bits = ++$dcnt * 8 unless defined $bits;
                        $iline = $ip . '/' . $bits;
                    }
                    if ($iline =~ /^$IPRe/o) {
                        my $rangeIP;
                        if (($rangeIP = eval{Net::IP->new($iline)}) && $valIP->overlaps($rangeIP)==${'Net::IP::IP_A_IN_B_OVERLAP'}) {
                            my $sl = $run->($rangeIP->ip(),0);
                            my $el = $run->($valIP->ip(),-1);
                            my $sh = $run->($valIP->last_ip(),1);
                            my $eh = $run->($rangeIP->last_ip(),0);
                            if ($sl && $el && $sh && $eh) {
                                my @cidr_l = $cidr_list->("$sl-$el");
                                my @cidr_h = $cidr_list->("$sh-$eh");
                                if ($sl ne $el || $sh ne $eh) {
                                    print $GPBFILE "##########\n";
                                    print $GPBFILE "# modified - removed: $value from >$line<\n";
                                    print $GPBFILE "# low  CIDR: @cidr_l\n" if $rangeIP->ip() ne $valIP->ip();
                                    print $GPBFILE "# high CIDR: @cidr_h\n" if $rangeIP->last_ip() ne $valIP->last_ip();
                                    print $GPBFILE "##########\n";
                                }
                                print $GPBFILE "$sl".($sl ne $el?"-$el":'')." $desc\n" if $rangeIP->ip() ne $valIP->ip();
                                print $GPBFILE "$sh".($sh ne $eh?"-$eh":'')." $desc\n" if $rangeIP->last_ip() ne $valIP->last_ip();
                                mlog(0,"$how: $value deleted from $parm - $text");
                                $ret = 1;
                                next;
                            }
                        } elsif (! $rangeIP) {
                            mlog(0,"warning: $iline seems not to be a valid IP-address or IP-address-range in line: $line");
                        }
                    }
                } else {
                    mlog(0,"warning: $value seems not to be a valid IP-address or IP-address-range");
                }
            }  # endif
            }; # end eval
            print $GPBFILE "$line\n";
        }
        close ($GPBFILE);
        $ConfigChanged = 1 if $ret;
        return $ret;
    } elsif ($whattodo eq 'add' && ! grep(/(?$case:^\Q$value\E)/,@cont)) {
        if (!$skipbackup) {
            unlink "$file.bak";
            copy("$file","$file.bak");
        }
        (open ($GPBFILE, '>>',"$file")) or (mlog(0,"error: unable to write to file $file for '$parm' to '$whattodo' entry") and return 0);
        binmode $GPBFILE;
        print $GPBFILE "\n$value  # added by GUI action or email interface - $text";
        close ($GPBFILE);
        mlog(0,"$how: $value added to $parm - $text");
        $ConfigChanged = 1;
        return 1;
    } elsif ($whattodo eq 'check') {
        grep(/(?$case:^\s*#\s*\Q$value\E)/,@cont) and return 1;
        grep(/(?$case:^\Q$value\E)/,@cont) and return 2;
        return -1;
    }
    return 0;};

    $GPBCompLibVer = sub {my($f1,$f2) = @_;
    d("GPBCompLibVer $f1 , $f2");
    return unless($f1 && $f2);
    return unless(-e $f1 && -e $f2);
    my $cmdf1;
    my $cmdf2;
    my ($mod) = $f1 =~ /^\Q$base\E\/(?:(?:download|lib|Plugins)\/)?(.+)\.p[ml]$/oi;
    $mod =~ s/\//::/go;
    my $perl = $perl;
    $perl =~ s/\"\'//go;
    if ($^O eq "MSWin32") {
        my $inc = join(' ', map {'-I "'.$_.'"'} @INC);
        $cmdf1 = '"' . $perl . '"' . " $inc -e \"require '$f1';print \$$mod"."::VERSION;\"";
        $cmdf2 = '"' . $perl . '"' . " $inc -e \"require '$f2';print \$$mod"."::VERSION;\"";
    } else {
        my $inc = join(' ', map {'-I \''.$_.'\''} @INC);
        $cmdf1 = '\'' . $perl . '\'' . " $inc -e \"require '$f1';print \$$mod"."::VERSION;\"";
        $cmdf2 = '\'' . $perl . '\'' . " $inc -e \"require '$f2';print \$$mod"."::VERSION;\"";
    }
    mlog(0,"info: version f1 command: $cmdf1") if $MaintenanceLog > 2;
    mlog(0,"info: version f2 command: $cmdf2") if $MaintenanceLog > 2;
    my $resf1 = qx($cmdf1);
    my $resf2 = qx($cmdf2);
    $resf1 =~ s/\r|\n//go;
    $resf2 =~ s/\r|\n//go;
    $resf1 = undef if $resf1 !~ /^\d+(?:\.\d+)?$/o;
    $resf2 = undef if $resf2 !~ /^\d+(?:\.\d+)?$/o;
    mlog(0,"info: found file versions: $f1 ($resf1) , $f2 ($resf2)") if $MaintenanceLog >= 2;
    return unless $resf2;
    return $resf2 if $resf2 gt $resf1;
    return;};

    $GPBinstallLib = sub {my ($url,$file) = @_;
    d("GPBinstallLib $url , $file");
    return 0 unless $url && $file;
    return 0 unless $GPBautoLibUpdate;
    my ($name) = $file =~ /\/?([^\/]+)$/io;
    $file="$base/$file" if $file!~/^\Q$base\E/io;
    copy("$base/download/$name","$base/tmp/$name.bak") if -e "$base/download/$name";
    if (! downloadHTTP($url,"$base/download/$name",0,$name,24,24,2,1)) {
        unlink("$base/tmp/$name.bak");
        return 0;
    }
    if (-e $file) {
        use File::Compare();
        my $ret = File::Compare::compare("$base/download/$name",$file);
        if ($ret == 0) { # files are equal - nothing to do
            mlog(0,"info: the most recent version of $name is still installed") if $MaintenanceLog;
            unlink("$base/tmp/$name.bak");
            return 0;
        } elsif (-e $file && $ret == -1) { # an error while compare
            mlog(0,"warning: unable to compare $base/download/$name and $file");
            unlink("$base/tmp/$name.bak");
            return 0;
        }
    }
    File::Copy::move("$base/tmp/$name.bak","$base/download/$name.bak") if -e "$base/tmp/$name.bak";

    if ($file =~ /\.p[lm]$/oi) {
        my $cmd;
        my $perl = $perl;
        $perl =~ s/\"\'//go;
        if ($^O eq "MSWin32") {
            my $inc = join(' ', map {'-I "'.$_.'"'} @INC);
            $cmd = '"' . $perl . '"' . " $inc -c \"$base/download/$name\" 2>&1";
        } else {
            my $inc = join(' ', map {'-I \''.$_.'\''} @INC);
            $cmd = '\'' . $perl . '\'' . " $inc -c \'$base/download/$name\' 2>&1";
        }
        my $res = qx($cmd);
        if ($res =~ /syntax\s+OK/igo) {
            mlog(0,"info: GPB-autoupdate: syntax check for '$file' returned OK");
        } else {
            mlog(0,"warning: GPB-autoupdate: syntax error in '$file' - skip $file update - syntax error is: $res");
            return 0;
        }
    }
    my $newVer = $GPBCompLibVer->($file,"$base/download/$name");
    unless ($newVer) {
        mlog(0,"info: the installed version of file $name is equal to, or newer than the downloaded version") if $MaintenanceLog;
        return 0;
    }
    mlog(0,"info: GPB-autoaupdate: successful downloaded version ($newVer) of $file in $base/download/$name");
    return 1 if ($GPBautoLibUpdate == 1 || ! -e $file);
    File::Copy::move($file,"$file.bak");
    copy("$base/download/$name",$file);
    mlog(0,"info: GPB-autoupdate: new version ($newVer) of $file was installed - restart required");
    return 1;};
}
