#line 1 "sub main::defineCanUseModules"
package main; sub defineCanUseModules {
    print "\t\t\t\t\t[OK]\nloading modules";
    print '.';

    %ModuleError = ();
    $AvailIOSocketINET6  = ($enableINET6 && $useIOSocketINET6) ? validateModule('IO::Socket::INET6+') : 0; # socket 6 IO module
    $CanUseIOSocketINET6 = $AvailIOSocketINET6 &&
      eval {
          my $sock = IO::Socket::INET6->new(Domain => AF_INET6, Listen => 1, LocalAddr => '[::]', LocalPort => $IPv6TestPort);
          if ($sock) {
              close($sock);
              $SysIOSocketINET6 = 1;
              1;
          } else {
              $AvailIOSocketINET6 = $SysIOSocketINET6 = 0;
              0;
          }
      };
    $CanUseThreadState   = $useThreadState ? validateModule('Thread::State') : 0;    # change thread priority
    $CanUseAvClamd       = $useFileScanClamAV ? validateModule('File::Scan::ClamAV') : 0;    # ClamAV module installed
    $AvailAvClamd        = $CanUseAvClamd;
    $CanUseLDAP          = $useNetLDAP ? validateModule('Net::LDAP') : 0;    # Net LDAP module installed
    print '.';
    $CanUseDNS           = $useNetDNS ? validateModule('Net::DNS') : 0;   # Net DNS module installed - required for SPF & RBL
    $AvailSPF2           = $useMailSPF ? validateModule('Mail::SPF') : 0;  # Mail SPF module installed
    $CanUseSPF2          = $AvailSPF2 && $CanUseDNS;  # SPF and dependancies installed
    print '.';
    $AvailSPF            = $useMailSPFQuery ? validateModule('Mail::SPF::Query') : 0;    # Mail SPF Query module installed
    $CanUseSPF           = $AvailSPF && $CanUseDNS; # SPF Query and dependancies installed
    $CanUseURIBL         = $CanUseDNS;                # URIBL and dependancies installed
    $CanUseRWL           = $CanUseDNS;                # RWL and dependancies installed
    print '.';
    $CanUseRBL           = $CanUseDNS;                # DNSBL and dependancies installed
    $AvailSRS            = $useMailSRS ? validateModule('Mail::SRS') : 0;  # Mail SRS module installed
    $CanUseSRS           = $AvailSRS;
    $AvailZlib           = $useCompressZlib ? validateModule('Compress::Zlib+') : 0;    # Zlib module installed
    $CanUseHTTPCompression  = $AvailZlib;
    $AvailMD5            = $useDigestMD5 ? validateModule('Digest::MD5+') : 0;   # Digest MD5 module installed
    $CanUseMD5Keys       = $AvailMD5;
    $AvailSHA1           = $useDigestSHA1 ? validateModule('Digest::SHA1 qw(sha1_hex)') : 0;   # Digest SHA1 module installed
    $CanUseSHA1          = $AvailSHA1;
    print '.';
    $AvailReadBackwards  = $useFileReadBackwards ? validateModule('File::ReadBackwards') : 0;    # ReadBackwards module installed;
    $CanSearchLogs       = $AvailReadBackwards;
    $AvailHiRes          = validateModule('Time::HiRes'); # Time::HiRes module installed;
    $CanStatCPU          = $AvailHiRes;
    $AvailIO             = $usePerlIOscalar ? validateModule('PerlIO::scalar+') : 0;    # make it chroot savy;
    $CanChroot           = $AvailIO;
    $AvailSyslog         = $useSysSyslog ? validateModule('Sys::Syslog qw( :DEFAULT setlogsock)') : 0;
    $CanUseSyslog        = $AvailSyslog;
    print '.';
    $useWin32APIOutputDebugString = $Config{useWin32APIOutputDebugString} = '' if ($^O ne 'MSWin32');
    $AvailWin32Debug     = $useWin32APIOutputDebugString ? validateModule('Win32::API::OutputDebugString qw(OutputDebugString DStr)') :0; # AZ: 2009-03-10 win32 debug/trace available
    $CanUseWin32Debug    = $AvailWin32Debug; # AZ: 2009-03-10 win32 debug/trace available
    $AvailTieRDBM        = $useTieRDBM ? validateModule('Tie::RDBM') : 0;    # Use external database
    $CanUseTieRDBM       = $AvailTieRDBM;
    $AvailDB_File        = $useDB_File ? validateModule('DB_File') : 0;    # Use external DB_File (Berkeley V1) database
    $CanUseDB_File       = $AvailDB_File;
    $AvailBerkeleyDB     = $useBerkeleyDB ? validateModule('BerkeleyDB') : 0;    # Use external Berkeley database
    $CanUseBerkeleyDB    = $AvailBerkeleyDB;
    print '.';
    $AvailCIDRlite       = $useNetCIDRLite ? validateModule('Net::CIDR::Lite') : 0;    # Net::CIDR::Lite module installed
    $CanUseCIDRlite      = $AvailCIDRlite;
    $AvailNetAddrIPLite  = $useNetAddrIPLite ? validateModule('NetAddr::IP::Lite()') : 0;    # NetAddr::IP::Lite module installed
    $CanUseNetAddrIPLite = $AvailNetAddrIPLite;
    $AvailNetIP          = $useNetIP ? validateModule('Net::IP()') : 0;    # Net::IP module installed
    $CanUseNetIP         = $AvailNetIP;

    $AvailLWP            = $useLWPSimple ? validateModule('LWP::Simple') && validateModule('HTTP::Request::Common') && validateModule('LWP::UserAgent') : 0;    # LWP::Simple module installed
    $CanUseLWP           = $AvailLWP;

    $AvailEMM            = $useEmailMIME ? validateModule('Email::MIME') : 0;  # Email::MIME module installed
    $CanUseEMM           = $AvailEMM;
    validateModule('MIME::Words()') if $CanUseEMM;
    $AvailMTY            = $useMIMETypes ? validateModule('MIME::Types') : 0;   # MIME::Types module installed
    $CanUseMTY           = $AvailMTY && $CanUseEMM;

    ${'Return::Value::NO_CLUCK'} = 1;   # prevent the cluck from Return::Value version 1.666002
    eval('use Return::Value();1;');
    $AvailEMS            = $useEmailSend ? validateModule('Email::Send') : 0;  # Email::Send module installed
    $CanUseEMS           = $AvailEMS;
    print '.';

    $AvailTNEF           = $useConvertTNEF ? validateModule('Convert::TNEF') : 0;  # Convert::TNEF module installed
    $CanUseTNEF          = $AvailTNEF && $CanUseMTY;

    $AvailDKIM           = $useMailDKIMVerifier ? validateModule('Mail::DKIM::Verifier') : 0;  # Mail::DKIM::Verifier module installed
    $CanUseDKIM          = $AvailDKIM;
    if ($CanUseDKIM) {validateModule('Mail::DKIM') ; validateModule('Mail::DKIM::Signer');}

    $AvailNetSMTP        = $useNetSMTP ? validateModule('Net::SMTP') : 0;  # Net::SMTP module installed
    $CanUseNetSMTP       = $AvailNetSMTP;

    $AvailNetSMTPSSL     = $useNetSMTPSSL ? validateModule('Net::SMTP::SSL') : 0;  # Net::SMTP::SSL module installed
    $CanUseNetSMTPSSL    = $AvailNetSMTPSSL;

    $AvailNetSNMPagent   = $useNetSNMPagent ?
    validateModule('NetSNMP::agent()') &&
    validateModule('NetSNMP::ASN()') &&
    validateModule('NetSNMP::default_store qq(:all)') &&
    validateModule('NetSNMP::agent::default_store qq(:all)')
     : 0 ;
    $CanUseNetSNMPagent  = $AvailNetSNMPagent;

    $AvailSchedCron      = $useScheduleCron ? validateModule('Schedule::Cron') : 0;  # Schedule::Cron module installed
    $CanUseSchedCron     = $AvailSchedCron;

    $AvailSysMemInfo     = $useSysMemInfo ? validateModule('Sys::MemInfo') : 0;  # Sys::MemInfo module installed
    $CanUseSysMemInfo    = $AvailSysMemInfo;

    $AvailSysCpuAffinity     = $useSysCpuAffinity ? validateModule('Sys::CpuAffinity') : 0;  # SSys::CpuAffinity module installed
    $CanUseSysCpuAffinity    = $AvailSysCpuAffinity;

    if ($CanUseIOSocketINET6) {
        $AvailIOSocketSSL    = $useIOSocketSSL ? validateModule('IO::Socket::SSL+') : 0;  # IO::Socket::SSL module installed
        $CanUseIOSocketSSL   = $AvailIOSocketSSL;
        validateModule('IO::Socket::INET6') if $CanUseIOSocketSSL;   # reimport the symbols in to namespace
    } else {
        $AvailIOSocketSSL    = $useIOSocketSSL ? validateModule('IO::Socket::SSL \'inet4\'') : 0;  # IO::Socket::SSL module installed
        $CanUseIOSocketSSL   = $AvailIOSocketSSL;
        validateModule('IO::Socket::INET') if $CanUseIOSocketSSL;   # reimport the symbols in to namespace
    }
    print '.';

    $AvailAuthenSASL    = $useAuthenSASL ? validateModule('Authen::SASL') : 0;  # Authen::SASL module installed
    $CanUseAuthenSASL   = $AvailAuthenSASL;

    $AvailRegexpOptimizer   = $useRegexpOptimizer ? validateModule('Regexp::Optimizer()') : 0;  # Regexp::Optimizer module installed
    if ($CanUseRegexpOptimizer = $AvailRegexpOptimizer) {
        $optReModule = 'Regexp::Optimizer' if eval('Regexp::Optimizer->VERSION') ge '0.23';
    }

    $AvailASSP_WordStem    = $useASSP_WordStem ? validateModule('ASSP_WordStem()') : 0;  # ASSP_WordStem  module installed
    $CanUseASSP_WordStem   = $AvailASSP_WordStem;

    $AvailASSP_FC    = $useASSP_FC ? validateModule('ASSP_FC()') : 0;  # ASSP_FC  module installed
    $CanUseASSP_FC   = $AvailASSP_FC;

    $AvailASSP_SVG    = $useASSP_SVG ? validateModule('ASSP_SVG()') : 0;  # ASSP_SVG  module installed
    $CanUseASSP_SVG   = $AvailASSP_SVG;

    $AvailAsspSelfLoader   = $useAsspSelfLoader ? defined $AsspSelfLoader::VERSION : 0;  # AsspSelfLoader  module installed
    $CanUseAsspSelfLoader  = $AvailAsspSelfLoader;

    $AvailUnicodeGCString = $useUnicodeGCString ?  validateModule('Unicode::GCString()') : 0;  # Unicode::GCString  module installed
    $CanUseUnicodeGCString = $AvailUnicodeGCString;

    $AvailTextUnidecode = $useTextUnidecode ?  validateModule('Text::Unidecode()') : 0;  # Text::Unidecode  module installed
    $CanUseTextUnidecode = $AvailTextUnidecode;

    $@ = undef;
    $CanUseWin32Unicode = $AvailWin32Unicode = ($useWin32Unicode && $] ge '5.012000') ? eval('
       if (   $^O eq \'MSWin32\'
           && defined ${chr(ord("\026") << 2)}
           && require Win32::Unicode
          )
       {
          $utf8 = sub {eval(\'Encode::_utf8_on($_[0]);\');};
          $unicodeFH = sub { $_[0] = Win32::Unicode::File->new; };
          $unicodeDH = sub { my $d = Win32::Unicode::Dir->new;my $c=shift;return unless $c;$utf8->($c);$d->open($c);my @l = $d->readdir;$d->close;return @l;};
          $open = sub {my @c=@_;return unless @c==3;$utf8->($c[2]);$unicodeFH->($_[0]);$_[0]->open($_[1],$c[2]);};
          $unlink = sub { my $c=shift;return unless $c;$utf8->($c);Win32::Unicode::File::unlinkW($c); };
          $move = sub { my @c=@_;return unless @c==2;for(@c){$utf8->($_);};Win32::Unicode::File::moveW(@c,1); };
          $copy = sub { my @c=@_;return unless @c==2;for(@c){$utf8->($_);};Win32::Unicode::File::copyW(@c,1); };
          $rename = sub { my @c=@_;return unless @c==2;for(@c){$utf8->($_);};Win32::Unicode::File::renameW(@c,1); };
          $eF = sub { my $c=shift;return unless $c;$utf8->($c);eval{Win32::Unicode::File::file_type(e => $c);}; };
          $dF = sub { my $c=shift;return unless $c;$utf8->($c);eval{Win32::Unicode::File::file_type(d => $c);}; };
          $stat = sub { my $c=shift;return unless $c;return unless $eF->($c);$utf8->($c);my @st; eval{@st = Win32::Unicode::File::statW($c);}; if ($@) {eval{@st = stat($c);};} return @st;};
          $mkdir = sub { my $c=shift; my $p=shift; return unless ($c && $p); return if $eF->($c); return if $dF->($c); $utf8->($c); Win32::Unicode::Dir::mkdirW($c)};
          $rmdir = sub { my $c=shift; return unless $c; return if ! $dF->($c); return if $c =~ /^\Q$base\E\/?$/o; $utf8->($c); Win32::Unicode::Dir::rmdirW($c)};
          $rmtree = sub { my $c=shift; return unless $c; return if ! $dF->($c); $utf8->($c); rmTree($c)};

          $unicodeName = sub {my $c=shift;return unless $c;$utf8->($c); eval(\'Win32::Unicode::File::CYGWIN\') ? Encode::encode_utf8($c) : Win32::Unicode::File::utf8_to_utf16(Win32::Unicode::File::catfile($c)) . "\x00";};
#          $unicodeName = sub {my $c=shift;return unless $c;$utf8->($c); Win32::Unicode::File::utf8_to_utf16(Win32::Unicode::File::catfile($c)) . "\x00";};
#          $unicodeName = sub {my $c=shift;return unless $c;$utf8->($c);Win32::Unicode::File::utf8_to_utf16(Win32::Unicode::File::catfile($c));};
          1;
       } else {
          0;
       }
    ') : 0;
    $ModuleError{'Win32::Unicode'} = $@ if $@;
    disableUnicode() unless $CanUseWin32Unicode;
    $canUnicode = $CanUseWin32Unicode || ($^O ne 'MSwin32' && $] ge '5.012000');
    print $canUnicode ? 'U' : 'u?';
    eval{${^WIDE_SYSTEM_CALLS} = 1;} if $canUnicode;

    if ($normalizeUnicode) {
        $CanUseUnicodeNormalize = eval('use Unicode::Normalize();1;');
        $ModuleError{'Unicode::Normalize'} = $@ if $@;
    }
    
    if (open(my $F, '>', "$base/moduleLoadErrors.txt")) {
        binmode $F;
        my $error;
        while (my($k,$v) = each %ModuleError) {
            print $F "module $k could not be loaded (see error below): check with >perl -e \"use $k;\"\n$v\n\n\n";
            $error = $error ? 'errors are' : 'error was';
        }
        if ($error) {
            print "\t\t\t\t[failed] - $error written to file $base/moduleLoadErrors.txt\n";
        } else {
            print $F "There were no module load errors detected.\n";
            print "\t\t\t\t[OK]\n";
        }
        close $F;
    }

    if ($CanUseTieRDBM){
      print "loading database drivers\t";
      @DBdriverNames = DBI->available_drivers;
      $DBdrivers = join('|',@DBdriverNames);
    } else {
      @DBdriverNames = ();
    }
    if ($CanUseBerkeleyDB) {
        unshift(@DBdriverNames, 'BerkeleyDB');
        $DBdrivers = 'BerkeleyDB|'.$DBdrivers;
    }
    $DBdrivers = "no database drivers (DBD-\<driver\> are available on your system" unless $DBdrivers;
    $DBdrivers =~ s/\|$//o;
}
