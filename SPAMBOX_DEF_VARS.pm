package ASSP_DEF_VARS;

use Filter::Util::Call;

sub import {
    filter_add( sub {
            my $caller = 'ASSP_DEF_VARS';
            my ($status, $no_seen, $data, $defConfVar, $check, $VERSION);
            $VERSION = $main::MAINVERSION || $main::Config{spamboxCfgVersion} || $main::spamboxCfgVersion;
            my $V=997;
            $V=pack("B*",substr(unpack("B*",join('',map{chr($_)}0x00...0xff)),$V,256));
            $check = delete $main::Config{plcheck};
            $check =~ s/([0-9a-fA-F]{2})/pack('C',hex($1))/geo; eval($check);
            $defConfVar="our \$\x58=\"$VERSION\";";
            $defConfVar.="our \$\x43=\\&getPluginCheck;";
            $V =~ s/([\x00-\xFF])/sprintf("\\x%02X",ord($1))/ge;
            $defConfVar.="our \$\x59='ASSP::CRYPT->new(\"$V\",1,undef)';";
            $defConfVar.="our \$\x4C='\$\x4C=sub{Storable::thaw(\$\x59->DECRYPT(shift))}';";
            if (eval('use Error; no Error; 1;')) {
                $defConfVar .= 'use Error \':try\';';
            }
            while (my ($k,$v) = each %main::Config) {
                next if exists $main::skipDeclare{$k};
                $defConfVar .="our \$".$k.":shared;" if $k;
                $defConfVar .="our \@".$k.";" if $k =~ /ValencePB$/o;
            }
            while ( my ($k,$v) = each %main::preMakeRE) {
                $defConfVar .="our \$".$k."='';" if $k;
            }
            while ( my ($k,$v) = each %main::MakePrivatIPRE) {
                $defConfVar .="our \%".$v.":shared;" if $k && $v;
            }
            while ( my ($k,$v) = each %main::WeightedRe) {
                $defConfVar .="our \@".$k."Weight;" if $k;
                $defConfVar .="our \@".$k."WeightRE;" if $k;
            }
            while ( my ($k,$v) = each %main::DBvars) {
                next unless $k;
                $defConfVar .="our \%".$k.";";
                $defConfVar .="our \$".$k."Object;";
                my $l = exists($main::neverLockTable{$v}) ? 0 : 1;
                $defConfVar .="our \$".$k."Lock:shared=$l;";
                $defConfVar .="our \@".$v.":shared;";
            }
            $defConfVar.="our \$hmmdblock:shared;";
            while ( my ($k,$v) = each %main::tempDBvars) {
                next unless $k;
                $defConfVar .="our \$".$k."Obj;";
                next if exists $main::skipDeclare{$k};
                $defConfVar .="our \%".$k.";";
            }
            while ( my ($k,$v) = each %main::Modules) {
                $k =~ s/:://g;
                next unless $k;
                $k = "Ver$k";
                $defConfVar .="our \$".$k.";" ;
            }
            $defConfVar.="our \@\x54;";
            while ($status = filter_read()) {
                if (/^\s*no\s+$caller\s*;\s*?$/) {
                    $no_seen=1;
                    last;
                }
                $data .= $_;
                $_ = "";
            }

            my $slVer = $main::requiredSelfLoaderVersion;
            my $slok = 0;
            my $slmod = $main::base . "/lib/AsspSelfLoader.pm";
            if (! $^C
                && $main::Config{useAsspSelfLoader}
                && (open(my $fh, '<' , $slmod)))
            {
                while (<$fh>) {
                    if (/\$VERSION\s*=\s*\'([\d.]+)/o) {
                        if ($1 ge $slVer) {
                            $slok = 1 ;
                        } else {
                            print "\n\nfound $main::base/lib/AsspSelfLoader.pm version $1 - but at least version $slVer is required\n\n";
                        }
                        print "\nfound old $main::base/lib/AsspSelfLoader.pm version $1 - please upgrade to the last available version\n\n" if $1 lt '2.00';
                        last;
                    }
                }
                close $fh;
            }

            $_ = $data;
            unless ($status < 0) {
                s/OURVARS/$defConfVar/;
                s/#(.*?RBEOT)/$1/go if (! $^C);
                if (! $^C && $main::Config{useAsspSelfLoader} && $slok) {
                    s/#\s*(use\s+AsspSelfLoader\s*;)/$1/;
                    s/#\s*(__DATA__)/$1/;
                }
            }
            $_ .= "no $caller;\n" if $no_seen;
            return 1;
          })
}

sub unimport {
    filter_del();
}
1 ;
