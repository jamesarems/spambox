#line 1 "sub main::init"
package main; sub init {
 my $ver;
 my $append;
 my $installed;
 $DataBaseDebug = $DataBaseDebug ? 1 : 0;
 if ($DBCacheSize) {
     my $size = $NumComWorkers * 2 + 8;
     $DBCacheSize = $size if $size > $DBCacheSize;
 }
 while (@prelog) {
     mlog(0, shift @prelog);
 }

 if($] lt '5.012003') {
   mlog(0, "warning: Perl version 5.012003 (5.12.3) is at least recommended to run SPAMBOX $version $modversion - you are running Perl version $] - please upgrade Perl");
 }
 if($] lt '5.012000') {
   mlog(0, "Perl version 5.012000 (5.12.0) is at least required to use the unicode Bayesian/HMM engine of SPAMBOX $version $modversion - you are running Perl version $] - please upgrade Perl");
 }
 my $p;
 $p = '-professional' if ($setpro && $globalClientName && $globalClientPass);
 $Y=eval($Y);
 if ($localhostname) {
     mlog(0,"SPAMBOX$p version $version$modversion (Perl $]) (on $^O)running on server: $localhostname ($localhostip)");
 } else {
     mlog(0,"SPAMBOX$p version $version$modversion (Perl $]) (on $^O) running on server: localhost ($localhostip)") ;
 }
 if ($canUnicode) {
     mlog(0,"info: unicode support is available on that system");
 } else {
     mlog(0,"info: unicode support is not available on that system");
 }
 if ($islendian) {
     mlog(0,"info: this system uses little-endianess");
 } else {
     mlog(0,"info: this system uses big-endianess");
 }

 checkVersionAge();

 print 'check process env ';

 if ($MaintenanceLog > 1) {
     mlog(0,"info: Perl will search for modules in the following folders:\n". join("\n",map {my $t = $_ ; $t = "'$t'";$t;} @INC));
     mlog(0,"info: beside the default Perl search pathes, this list has to contain:\n$base\n$base/lib\n$base/Plugins");
 }

 if ($HMM4ISP) {
     mlog(0,"info: checking HMM4ISP setup");
     if (! $spamdb || $spamdb =~ /DB:/io) {
         $HMM4ISP = 0;
         mlog(0,"error: HMM4ISP is set to enabled, but spamdb has a wrong setting '$spamdb'!");
     }
     if ($HMMusesBDB) {
         $HMM4ISP = 0;
         mlog(0,"error: HMM4ISP is set to enabled, but HMMusesBDB is switched to 'ON'!");
     }
     if ($threadReloadConfigDelay < 5) {
         mlog(0,"warning: threadReloadConfigDelay is set to $threadReloadConfigDelay seconds - this is too less (min 5s) - the default value of 15 seconds is used!");
         $threadReloadConfigDelay = 15;
     }
     if ($threadReloadConfigDelay > 60) {
         mlog(0,"warning: threadReloadConfigDelay is set to $threadReloadConfigDelay seconds - this is too high (max 60s) - the default value of 15 seconds is used!");
         $threadReloadConfigDelay = 15;
     }
     if ($HMM4ISP) {
         mlog(0,"info: the HMM4ISP setup is OK");
     } else {
         mlog(0,"error: the HMM4ISP setup is wrong  - HMM4ISP is now disabled!");
     }
 }
 
 $MailCount = 0;

 readNorm();

 &initGlobalThreadVar();

 $MinPollTimeT =  $MinPollTime ? $MinPollTime : 1 ;
 $pollwait = $MinPollTimeT/1000;
 $minSelectTime = 0.001;

 {
     my $s;
     for (@nameservers) {
         my ($address,$port) = /^($IPRe)(\:$PortRe)?$/o;
         eval {$s = IO::Socket::INET->new(Proto=>'udp',PeerAddr=>$address,PeerPort=>($port || 53));};
         mlog(0,"error: can't contact DNS-server ($address) - $@") unless $s;
         last if $s;
     }
     if ($s) {
         my $sel = IO::Select->new;
         $sel->add($s);
         my $i = Time::HiRes::time();
         my @r = $sel->can_read( 0.001 );
         $i = Time::HiRes::time() - $i;
         $minSelectTime = ($i >= 1) ? 1 : 0.001;
         mlog(0,"warning: the system select->() call of your operating system does not support milliseconds as timeout value - USE ANOTHER OPERATING SYSTEM !!!") if ($i >= 1);
     } else {
         mlog(0,"error: can't contact any DNS-server (@nameservers) - DNSReuseSocket is unselected");
         $DNSReuseSocket = $Config{DNSReuseSocket} = '';
     }
 }

 my $perlver=$];
 eval($L);
 $WorkerName = 'init';
  if ( $^O eq 'MSWin32' ) {
       eval{
           mlog(0,'info: analysing windows system environment');
           my @msvcrt;
           my @where = split(/;/o,$ENV{'PATH'});
           my $perls = $perl;
           $perls =~ s/\\[^\\]+$//o;
           $perls =~ s/\\[^\\]+$//o;
           $perls .= '\site\bin';
           unshift (@where, $perls);
           my $perl = $perl;
           $perl =~ s/\\[^\\]+$//o;
           unshift (@where, $perl);
           my $dbase = $base;
           $dbase =~ s/\//\\/go;
           $dbase =~ s/[\\|\/]*$//o;
           unshift (@where, $dbase);
           my $path_to_msvcrt;
           while ( my $pdir = shift @where) {
               if (-e "$pdir/msvcrt.dll") {
                   $path_to_msvcrt = $pdir;
                   last;
               }
           }
           $path_to_msvcrt =~ s/[\\|\/]*$//o;
           if (lc $path_to_msvcrt ne lc ($ENV{'SystemRoot'}.'\system32')) {
               mlog(0,"warning: Perl seems to use the C-runtime library 'msvcrt.dll' in directory $path_to_msvcrt, this should be MS-C-runtime library 'msvcrt.dll' in directory ".$ENV{'SystemRoot'}.'\system32. Your environment variable -PATH- is possibly wrong set!');
               print "\t\t\t\t\t[warning]";
           } else {
               mlog(0,'info: windows system environment looks OK');
               print "\t\t\t\t\t[OK]";
           }
       };
       if ($@) {
           mlog(0,"warning: unable to analyse windows system environment - $@");
           print "\t\t\t\t\t[ERROR]";
       }
  } else {

       print "\t\t\t\t\t[SKIP]";
  }
  if ( $perlver > "5.999999") {
       mlog(0,"Perl version $perlver is not supported for SPAMBOX Version 2.x.x!");
  }

  print "\ncheck process permission";

  my $tmpSPAMBOXout;
  my $StartError;
  if (open($tmpSPAMBOXout, ">", "$base/aaaa_tmp.pl")) {
      binmode $tmpSPAMBOXout;
      close $tmpSPAMBOXout;
      my $assp = $assp;
      $assp =~ s/\\/\//og;
      $assp = $base.'/'.$assp if ($assp !~ /\Q$base\E/io);
      $asspCodeMD5 = eval {getMD5File($assp);};
      copy("$assp","$base/aaaa_tmp.pl");
      if (-e ($assp.'.run')) {
          unlink($assp.'.run') or mlog(0,"error: unable to remove old saved running script '$assp.run' - $!");
      }
      copy("$assp",$assp.'.run') or mlog(0,"error: unable to save current running script to file '$assp.run'");
      unless (rename("$base/aaaa_tmp.pl","$base/aaaa_tmpx.pl") && unlink("$base/aaaa_tmpx.pl")) {
        mlog(0,'************************************************************');
        mlog(0,"error: this process is unable to rename and/or delete files in directory $base");
        mlog(0,"error: $!");
        mlog(0,'error: check permission and disable all online virusscanners for this directory');
        mlog(0,'error: remove manually the files aaaa_tmp.pl and aaaa_tmpx.pl from this directory');
        mlog(0,'error: restart assp');
        mlog(0,'************************************************************');
        $StartError = 1;
            print "\t\t\t\t[ERROR]";
      } else {
            print "\t\t\t\t[OK]";
      }
  } else {
      mlog(0,'************************************************************');
      mlog(0,"error: this process is unable to write in to directory $base");
      mlog(0,"error: $!");
      mlog(0,'error: check permission and disable all online virusscanners for this directory');
      mlog(0,'error: remove manually the files aaaa_tmp.pl and aaaa_tmpx.pl from this directory');
      mlog(0,'error: restart assp');
      mlog(0,'************************************************************');
      $StartError = 1;
      print "\t\t\t\t[ERROR]";
  }
  unlink("$base/aaaa_tmp.pl");

  print "\nsetting up modules";

  $append = '';
  $ver=threads->VERSION;
  $append = '- please upgrade to version 1.74 or higher' if ($ver lt '1.74');
  mlog(0,"threads module $ver installed $append");
  $ModuleList{'threads'} = $ver.'/1.74';
  print '.';

  $append = '';
  $ver=threads::shared->VERSION;
  $append = '- please upgrade to version 1.32 or higher' if ($ver lt '1.32');
  mlog(0,"threads::shared module $ver installed $append");
  $ModuleList{'threads::shared'} = $ver.'/1.32';
  print '.';

  $append = '';
  $ver=Thread::Queue->VERSION;
  $append = '- please upgrade to version 2.11 or higher' if ($ver lt '2.11');
  mlog(0,"Thread::Queue module $ver installed $append");
  $ModuleList{'Thread::Queue'} = $ver.'/2.11';
  print '.';

  $append = '';
  $ver=IO::Poll->VERSION;
  $ver =~ s/0+$//o;
  $append = '- please upgrade to version 0.07' if ($ver lt '0.07');
  mlog(0,"IO::Poll module $ver installed $append");
  $ModuleList{'IO::Poll'} = $ver.'/0.07';

  $append = '';
  $ver=IO::Select->VERSION;
  $append = '- please upgrade to version 1.17' if ($ver lt '1.17');
  mlog(0,"IO::Select module $ver installed $append");
  $ModuleList{'IO::Select'} = $ver.'/1.17';

  if ($IOEngineRun == 0) {
      mlog(0,'SPAMBOX is using IOEngine - Poll');
  } else {
      mlog(0,'SPAMBOX is using IOEngine - select');
  }

  if ($CanUseThreadState) {
    $ver=eval('Thread::State->VERSION'); $VerThreadState=$ver;
    if ($ver ge '0.09') {
        $ver=" version $ver" if $ver;
        mlog(0,"Thread::State module$ver installed and available");
    } else {
        $ver=" version $ver" if $ver;
        mlog(0,"Thread::State module$ver installed - but version 0.09 or higher is required - Thread::State is not available");
        $CanUseThreadState = 0;
    }
    $installed = 'enabled';
  } else {
    $installed = $useThreadState ? 'is not installed' : 'is disabled in config';
    mlog(0,"Thread::State 0.09 module $installed.");
  }
  $ModuleList{'Thread::State'} = $VerThreadState.'/0.09';
  $ModuleStat{'Thread::State'} = $installed;

  $ver = IO::Socket->VERSION;
  if ($ver lt '1.30') {
      *{'IO::Socket::blocking'} = *{'main::assp_socket_blocking'};   # MSWIN32 fix for nonblocking Sockets
      mlog(0,"IO::Socket version $ver is too less - recommended is at least 1.30_01 - hook ->blocking to internal procedure");
  }
  print '.';

  if ($CanUseIOSocketINET6 || $SysIOSocketINET6 == 0) {
    $ver=eval('IO::Socket::INET6->VERSION'); $VerIOSocketINET6=$ver; $ver=" version $ver" if $ver;
    my $sys = ($SysIOSocketINET6 == 1) ? '' : ' - but IPv6 is not supported by your system';
    mlog(0,"IO::Socket::INET6 module$ver installed and available$sys");
    mlog(0,'please upgrade the module IO::Socket::INET6 to version 2.67 or higher') if ($VerIOSocketINET6 lt '2.67');
    $installed = ($SysIOSocketINET6 == 1) ? 'enabled' : 'not supported';
  } else {
    $installed = $useIOSocketINET6 ? 'is not installed' : 'is disabled in config';
    $installed = 'is not detected ( enableINET6 is not set )' unless $enableINET6;
    mlog(0,"IO::Socket::INET6 module $installed.");
  }
  $ModuleList{'IO::Socket::INET6'} = $VerIOSocketINET6.'/2.67';
  $ModuleStat{'IO::Socket::INET6'} = $installed;

  if ($CanUseAvClamd) {
    *{'File::Scan::ClamAV::ping'} = *{'main::ClamScanPing'};
    *{'File::Scan::ClamAV::streamscan'} = *{'main::ClamScanScan'};
    my $clamavd = File::Scan::ClamAV->new(port => $AvClamdPort);
    if($clamavd->ping()) {
      $AvailAvClamd = 1;
      $ver = $clamavd->VERSION;
      $VerFileScanClamAV=$ver; $ver=" version $ver" if $ver;
      $ModuleList{'File::Scan::ClamAV'} = $VerFileScanClamAV.'/1.8';
      $ModuleStat{'File::Scan::ClamAV'} = 'enabled';
      mlog(0,"File::Scan::ClamAV module$ver installed and available");
    } else {
      $AvailAvClamd = 0;
      $ver = $clamavd->VERSION;
      $VerFileScanClamAV=$ver; $ver=" version $ver" if $ver;
      $ModuleList{'File::Scan::ClamAV'} = $VerFileScanClamAV.'/1.8';
      mlog(0,"File::Scan::ClamAV module$ver installed but not available, error: ".$clamavd->errstr());
      $ModuleStat{'File::Scan::ClamAV'} = $clamavd->errstr();
    }
  } else {
    $AvailAvClamd = 0;
    $VerFileScanClamAV = '';
    $ModuleList{'File::Scan::ClamAV'} = $VerFileScanClamAV.'/1.8';
    $installed = $useFileScanClamAV ? 'is not installed' : 'is disabled in config';
    mlog(0,"File::Scan::ClamAV module $installed.") if $UseAvClamd;
    $ModuleStat{'File::Scan::ClamAV'} = $installed;
  }
  print '.';

  if ($CanUseLDAP) {
    $ver=eval('Net::LDAP->VERSION'); $VerNetLDAP=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Net::LDAP module$ver installed and available");
    $installed = 'enabled';
  } else {
    $installed = $useNetLDAP ? 'is not installed' : 'is disabled in config';
    mlog(0,"Net::LDAP module $installed.") if $DoLDAP;
  }
  $ModuleList{'Net::LDAP'} = $VerNetLDAP.'/0.33';
  $ModuleStat{'Net::LDAP'} = $installed;

  if ($CanUseDNS) {
    $ver=eval('Net::DNS->VERSION'); $VerNetDNS=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Net::DNS module$ver installed and available");
    $installed = 'enabled';
    my $d = Net::DNS::Resolver->new();
    $orgNewDNSResolver = \&Net::DNS::Resolver::Base::new;
    *Net::DNS::Resolver::Base::new = \&getDNSResolver;
    $d = eval{ Net::DNS::Resolver->send(); };
    $orgSendDNSResolver = \&Net::DNS::Resolver::Base::send;
    *Net::DNS::Resolver::Base::send = \&DNSResolverSend;
    $orgNewDNSisSET = 1;
  } else {
    $installed = $useNetDNS ? 'is not installed' : 'is disabled in config';
    mlog(0,"Net::DNS module $installed.");
  }
  $ModuleList{'Net::DNS'} = $VerNetDNS.'/0.61';
  $ModuleStat{'Net::DNS'} = $installed;

  if ($CanUseNetSMTP) {
    $ver=eval('Net::SMTP->VERSION'); $VerNetSMTP=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Net::SMTP module$ver installed and available");
    *{'Net::SMTP::DESTROY'} = \&Net::SMTP::DESTROY_SSLNS;
    *{'Net::SMTP::starttls'} = \&Net::SMTP::assp_starttls;
    if ($VerNetSMTP >= '3.00') {
        @Net::SMTP::ISA = map {$_ eq 'IO::Socket::INET6' ? 'IO::Socket::INET' : $_;} @Net::SMTP::ISA;
        mlog(0,"warning: the module Net::SMTP version $VerNetSMTP wants to load the perl module IO::Socket::IP - please install this module or run the latest $base/assp.mod/install/mod_inst.pl")
           unless (grep(/IO\:\:Socket\:\:IP/o,@Net::SMTP::ISA));
    }
    $installed = 'enabled';
  } else {
    $installed = $useNetSMTP ? 'is not installed' : 'is disabled in config';
    mlog(0,"Net::SMTP module $installed.");
  }
  $ModuleList{'Net::SMTP'} = $VerNetSMTP.'/2.31';
  $ModuleStat{'Net::SMTP'} = $installed;

  if ($CanUseNetSMTPSSL) {
    $ver=eval('Net::SMTP::SSL->VERSION'); $VerNetSMTPSSL=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Net::SMTP::SSL module$ver installed and available");
    *{'Net::SMTP::SSL::new'} = \&Net::SMTP::SSL::NSSL_new;
    $installed = 'enabled';
  } else {
    $installed = $useNetSMTPSSL ? 'is not installed' : 'is disabled in config';
    mlog(0,"Net::SMTP::SSL module $installed.");
  }
  $ModuleList{'Net::SMTP::SSL'} = $VerNetSMTPSSL.'/1.01';
  $ModuleStat{'Net::SMTP::SSL'} = $installed;

  if ($CanUseNetSNMPagent) {
    $ver=eval('NetSNMP::agent->VERSION'); $VerNetSNMPagent=$ver; $ver=" version $ver" if $ver;
    ;
    foreach (@NetSNMP::ASN::EXPORT) {
        eval ('$SNMPAS{$_} = NetSNMP::ASN::constant($_, 0);1;') ||
        eval ('$SNMPAS{$_} = NetSNMP::ASN::constant($_);1;') ||
        ( mlog(0,"error: unable to get constant ($_) for NetSNMP::ASN - $@") &&
          ($installed = 'ASN constant error') && ($CanUseNetSNMPagent = ''));
    }
    foreach (@NetSNMP::agent::EXPORT) {
        eval ('$SNMPag{$_} = NetSNMP::agent::constant($_, 0);1;') ||
        eval ('$SNMPag{$_} = NetSNMP::agent::constant($_);1;') ||
        ( mlog(0,"error: unable to get constant ($_) for NetSNMP::agent - $@") &&
          ($installed = 'agent constant error') && ($CanUseNetSNMPagent = ''));
    }
    if ($CanUseNetSNMPagent) {
        mlog(0,"NetSNMP::agent module$ver installed and available");
    } else {
        mlog(0,"NetSNMP::agent module$ver installed but disabled because of an '$installed'");
    }
  } else {
    $installed = $useNetSNMPagent ? 'is not installed' : 'is disabled in config';
    mlog(0,"NetSNMP::agent module $installed.");
  }
  $ModuleList{'NetSNMP::agent'} = $VerNetSNMPagent.'/5.05';
  $ModuleStat{'NetSNMP::agent'} = $installed;

  if ($CanUseSPF) {
    $ver=eval('Mail::SPF::Query->VERSION'); $VerMailSPF=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Mail::SPF::Query module$ver installed and available");
    $installed = 'enabled';
  } elsif ($AvailSPF) {
    $ver=eval('Mail::SPF::Query->VERSION'); $ver=" version $ver" if $ver;
    mlog(0,"Mail::SPF::Query module$ver installed but Net::DNS required");
    $installed = 'Net::DNS required';
  } else {
    $installed = $useMailSPFQuery ? 'is not installed' : 'is disabled in config';
    mlog(0,"Mail::SPF::Query module $installed.") if $ValidateSPF;
  }
  $ModuleList{'Mail::SPF::Query'} = $VerMailSPF.'/1.999001';
  $ModuleStat{'Mail::SPF::Query'} = $installed;

  if ($CanUseSPF2) {
   $ver        = eval('Mail::SPF->VERSION');
   $ver        =~ s/^v//gio; # strip leading 'v'
   $VerMailSPF = $ver;
   $ver        = " version $ver" if $ver;
   if ( $VerMailSPF >= 2.007 ) {
    mlog(0, "Mail::SPF module$ver installed and available" );
    $installed = 'enabled';
   } else {
    mlog(0, "Mail::SPF module$ver installed but must be >= 2.007" );
    mlog(0, 'Mail::SPF will not be used.' );
    $CanUseSPF2 = 0;
    $installed = 'wrong version';
   }
  } elsif ($AvailSPF2) {
   $ver = eval('Mail::SPF->VERSION');
   $ver =~ s/^v//gio; # strip leading 'v'
   $ver = " version $ver" if $ver;
   mlog(0, "Mail::SPF module$ver installed but Net::DNS required" );
   $installed = 'Net::DNS required';
  } else {
   $installed = $useMailSPF ? 'is not installed' : 'is disabled in config';
   mlog(0, "Mail::SPF module $installed." ) if $ValidateSPF;
  } 
  $ModuleList{'Mail::SPF'} = $VerMailSPF.'/2.007';
  $ModuleStat{'Mail::SPF'} = $installed;

  if ($CanUseSRS) {
    $ver=eval('Mail::SRS->VERSION'); $VerMailSRS=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Mail::SRS module$ver installed - Sender Rewriting Scheme available");
    $installed = 'enabled';
  } elsif (!$AvailSRS) {
    $installed = $useMailSRS ? 'is not installed' : 'is disabled in config';
    mlog(0,"Mail::SRS module $installed - Sender Rewriting Scheme disabled") if $EnableSRS;
  }
  $ModuleList{'Mail::SRS'} = $VerMailSRS.'/0.31';
  $ModuleStat{'Mail::SRS'} = $installed;

  if ($CanUseHTTPCompression) {
    $ver=eval('Compress::Zlib->VERSION'); $VerCompressZlib=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Compress::Zlib module$ver installed - HTTP compression available");
    $installed = 'enabled';
  } elsif (!$AvailZlib) {
    $installed = $useCompressZlib ? 'is not installed' : 'is disabled in config';
    mlog(0,"Compress::Zlib module $installed - HTTP compression disabled");
  }
  $ModuleList{'Compress::Zlib'} = $VerCompressZlib.'/2.008';
  $ModuleStat{'Compress::Zlib'} = $installed;

  if ($CanUseMD5Keys) {
    $ver=eval('Digest::MD5->VERSION'); $VerDigestMD5=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Digest::MD5 module$ver installed - delaying can use MD5 keys for hashes");
    $installed = 'enabled';
  } else {
    $installed = $useDigestMD5 ? 'is not installed' : 'is disabled in config';
    mlog(0,"Digest::MD5 module $installed - delaying can not use MD5 keys for hashes");
  }
  $ModuleList{'Digest::MD5'} = $VerDigestMD5.'/2.36_01';
  $ModuleStat{'Digest::MD5'} = $installed;

  if ($CanUseSHA1) {
    $ver=eval('Digest::SHA1->VERSION'); $VerDigestSHA1=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Digest::SHA1 module$ver installed - BATV and FBMTV check available");
    $installed = 'enabled';
  } else {
    $installed = $useDigestSHA1 ? 'is not installed' : 'is disabled in config';
    mlog(0,"Digest::SHA1 module $installed - BATV and FBMTV check not available");
  }
  $ModuleList{'Digest::SHA1'} = $VerDigestSHA1.'/2.11';
  $ModuleStat{'Digest::SHA1'} = $installed;

  if ($CanSearchLogs) {
    $ver=eval('File::ReadBackwards->VERSION'); $VerFileReadBackwards=$ver; $ver=" version $ver" if $ver;
    mlog(0,"File::ReadBackwards module$ver installed - searching of log files enabled");
    $installed = 'enabled';
  } elsif (!$AvailReadBackwards) {
    $installed = $useFileReadBackwards ? 'is not installed' : 'is disabled in config';
    mlog(0,"File::ReadBackwards module $installed - searching of log files disabled");
  }
  $ModuleList{'File::ReadBackwards'} = $VerFileReadBackwards.'/1.04';
  $ModuleStat{'File::ReadBackwards'} = $installed;

  if ($CanStatCPU) {
    $ver=eval('Time::HiRes->VERSION'); $VerTimeHiRes=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Time::HiRes module$ver installed - CPU usage statistics available");
  }
  $ModuleList{'Time::HiRes'} = $VerTimeHiRes.'/1.9707';
  $ModuleStat{'Time::HiRes'} = 'enabled';

  if ($CanChroot) {
    $ver=eval('PerlIO::scalar->VERSION'); $VerPerlIOscalar=$ver; $ver=" version $VerPerlIOscalar" if $ver;
    if ($ChangeRoot) {
        mlog(0,"PerlIO::scalar module$ver installed - chroot savy");
        mlog(0,"error: ChangeRoot - /etc/protocols in $ChangeRoot not found!") unless -e "$ChangeRoot/etc/protocols";
    }
    $installed = 'enabled';
  } else {
    $installed = $usePerlIOscalar ? 'is not installed' : 'is disabled in config';
    mlog(0,"PerlIO::scalar module $installed - chroot not available") if $ChangeRoot;
  }
  $ModuleList{'PerlIO::scalar'} = $VerPerlIOscalar.'/0.05';
  $ModuleStat{'PerlIO::scalar'} = $installed;

  if ($CanUseSyslog){
    $ver=eval('Sys::Syslog->VERSION'); $VerSysSyslog=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Sys::Syslog module$ver installed - Unix centralized logging enabled");
    $installed = 'enabled';
  } elsif (!$AvailSyslog ) {
    $installed = $useSysSyslog ? 'is not installed' : 'is disabled in config';
    mlog(0,"Sys::Syslog module $installed.") if $sysLog && !$sysLogPort;
  }
  $ModuleList{'Sys::Syslog'} = $VerSysSyslog.'/0.25';
  $ModuleStat{'Sys::Syslog'} = $installed;

  if ($CanUseWin32Daemon){
    $ver=eval('Win32::Daemon->VERSION'); $VerWin32Daemon=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Win32::Daemon module$ver installed - can run as Win32 service") if ( $^O eq 'MSWin32' );
    $installed = 'enabled';
  } else {
    $installed = $useWin32Daemon ? 'is not installed' : 'is disabled in config';
    mlog(0,"Win32::Daemon module $installed - unable to run as Win32 service") if ( $^O eq 'MSWin32' );
  }
  $ModuleList{'Win32::Daemon'} = $VerWin32Daemon.'/20080324';
  $ModuleStat{'Win32::Daemon'} = $installed;

  if ($CanUseWin32Debug){
    $ver=eval('Win32::API::OutputDebugString->VERSION'); $VerWin32APIOutputDebugString=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Win32::API::OutputDebugString module$ver installed - can debug to Win32 debug API") if ( $^O eq 'MSWin32' );
    $installed = 'enabled';
  } else {
    $installed = $useWin32APIOutputDebugString ? 'is not installed' : 'is disabled in config';
    mlog(0,"Win32::API::OutputDebugString module $installed - unable to debug to Win32 API") if ( $^O eq 'MSWin32' );
  }
  $ModuleList{'Win32::API::OutputDebugString'} = $VerWin32APIOutputDebugString.'/0.03';
  $ModuleStat{'Win32::API::OutputDebugString'} = $installed;

  if ($CanUseUnicodeGCString){
    $ver=eval('Unicode::GCString->VERSION'); $VerUnicodeGCString=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Unicode::GCString module$ver installed - can detect east asian language strings as sequence of UAX #29 Grapheme Clusters to analyze Bayes and HMM");
    $installed = 'enabled';
    $requiredDBVersion{'Spamdb'} .= '_UAX#29';
    $requiredDBVersion{'HMMdb'}  .= '_UAX#29';
  } else {
    $installed = $useUnicodeGCString ? 'is not installed' : 'is disabled in config';
    mlog(0,"Unicode::GCString module $installed - unable to detect east asian language strings as sequence of UAX #29 Grapheme Clusters");
  }
  $ModuleList{'Unicode::GCString'} = $VerUnicodeGCString.'/2012.04';
  $ModuleStat{'Unicode::GCString'} = $installed;

  if ($CanUseUnicodeNormalize && $normalizeUnicode) {
    $requiredDBVersion{'Spamdb'} .= '_UAX#15';
    $requiredDBVersion{'HMMdb'}  .= '_UAX#15';
    mlog(0,"Unicode::Normalize module is installed and 'unicodeNormalize' is enabled - NFKC unicode normalization is globaly enabled");
  }

  if ($CanUseTextUnidecode){
    $ver=eval('Text::Unidecode->VERSION'); $VerTextUnidecode=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Text::Unidecode module$ver installed - can transliterate unicode characters to ASCII");
    $installed = 'enabled';
  } else {
    $installed = $useTextUnidecode ? 'is not installed' : 'is disabled in config';
    mlog(0,"Text::Unidecode module $installed - unable to transliterate unicode characters to ASCII");
  }
  $ModuleList{'Text::Unidecode'} = $VerTextUnidecode.'/0.04';
  $ModuleStat{'Text::Unidecode'} = $installed;

  if ($CanUseWin32Unicode){
    $ver=eval('Win32::Unicode->VERSION'); $VerWin32Unicode=$ver; $ver=" version $ver" if $ver;
    if ($VerWin32Unicode <= '0.32' or $VerWin32Unicode >= '0.37') {
        $installed = 'enabled';
        if ( $^O eq 'MSWin32' ) {
            mlog(0,"Win32::Unicode module$ver installed - can write unicode filenames to OS");
            *{'Win32::Unicode::File::flush'} = *{'main::assp_flush'} unless defined *{'Win32::Unicode::File::flush'};
        }
    } else {
        disableUnicode();
        eval{${^WIDE_SYSTEM_CALLS} = 0;};
        $canUnicode = undef;
        eval('no Win32::Unicode;');
        $installed = 'disabled - version BUG';
        mlog(0,"Win32::Unicode module version $VerWin32Unicode is buggy and is disabled now - upgrade to at least version 0.37 - unable to write unicode filenames to OS") if ( $^O eq 'MSWin32' );
    }
  } else {
    $installed = $useWin32Unicode ? 'is not installed' : 'is disabled in config';
    mlog(0,"Win32::Unicode module $installed - unable to write unicode filenames to OS") if ( $^O eq 'MSWin32' );
  }
  $ModuleList{'Win32::Unicode'} = $VerWin32Unicode.'/0.37';
  $ModuleStat{'Win32::Unicode'} = $installed;

  if ($CanUseTieRDBM) {
    $ver=eval('Tie::RDBM->VERSION'); $VerTieRDBM=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Tie::RDBM module$ver installed - database usage available");
    *{'Tie::RDBM::_update'}  = *{'main::rdbm_update'};
    *{'Tie::RDBM::_insert'}  = *{'main::rdbm_insert'};
    *{'Tie::RDBM::FETCH'}    = *{'main::rdbm_fetch'};
    *{'Tie::RDBM::DELETE'}   = *{'main::rdbm_delete'};
    *{'Tie::RDBM::FIRSTKEY'} = *{'main::rdbm_firstkey'};
    *{'Tie::RDBM::NEXTKEY'}  = *{'main::rdbm_nextkey'};
    *{'Tie::RDBM::CLEAR'}    = *{'main::rdbm_CLEAR'};
    *{'Tie::RDBM::STORE'}    = *{'main::rdbm_STORE'};
    *{'Tie::RDBM::EXISTS'}   = *{'main::rdbm_EXISTS'};
    *{'Tie::RDBM::DESTROY'}  = *{'main::rdbm_DESTROY'};
    *{'Tie::RDBM::SCALAR'}   = *{'main::rdbm_COUNT'};
    $installed = 'enabled';
  } elsif (!$AvailTieRDBM ) {
    $installed = $useTieRDBM ? 'is not installed' : 'is disabled in config';
    mlog(0,"Tie::RDBM module $installed - database usage not available");
  }
  $ModuleList{'Tie::RDBM'} = $VerTieRDBM.'/0.70';
  $ModuleStat{'Tie::RDBM'} = $installed;

  if ($CanUseDB_File) {
    $ver=eval('DB_File->VERSION'); $VerDB_File=$ver; $ver=" version $ver" if $ver;
    mlog(0,"DB_File module$ver installed - DB_File (Berkeley V1) database usage available");
    $installed = 'enabled';
  } elsif (!$AvailDB_File ) {
    $installed = $useDB_File ? 'is not installed' : 'is disabled in config';
    mlog(0,"DB_File module $installed - DB_File (Berkeley V1) database usage not available");
  }
  $ModuleList{'DB_File'} = $VerDB_File.'/1.816';
  $ModuleStat{'DB_File'} = $installed;

  my $BDBver;
  my $BDBverStr;
  if ($CanUseBerkeleyDB) {
    my $fail = 0;
    $ver=eval('BerkeleyDB->VERSION'); $VerBerkeleyDB=$ver; $ver=" version $ver" if $ver;
    $BDBver = eval('$BerkeleyDB::db_version;');
    $BDBverStr = eval('BerkeleyDB->DB_VERSION_STRING');
    if ($BDBver lt '4.5') {
        $AvailBerkeleyDB = $CanUseBerkeleyDB = 0;
        mlog(0,"warning: BerkeleyDB database version $BDBver / $BDBverStr installed - but at least version 4.5 is required - Berkeley database usage not available");
        $fail = 1;
        $installed = 'wrong engine version';
        $ModuleStat{'BerkeleyDB_DBEngine'} = $installed;
        $Config{clearBerkeleyDBEnv} = 1;
        $runHMMusesBDB = 0;
    }
    if ($VerBerkeleyDB lt '0.34') {
        $AvailBerkeleyDB = $CanUseBerkeleyDB = 0;
        mlog(0,"warning: BerkeleyDB module $ver installed - but at least version 0.34 is required - Berkeley database usage not available");
        $fail = 1;
        $installed = 'wrong module version';
        $Config{clearBerkeleyDBEnv} = 1;
        $runHMMusesBDB = 0;
    }
    if (! $fail) {
        mlog(0,"BerkeleyDB module$ver installed - Berkeley database usage available");
        mlog(0,"BerkeleyDB DB-version $BDBver / $BDBverStr is installed");
        $installed = 'enabled';
        $ModuleStat{'BerkeleyDB_DBEngine'} = $installed;
        if ($BDBverStr ne $Config{BerkeleyDB_DBEngine}) {
            $Config{clearBerkeleyDBEnv} = 1;
            $newConfig{BerkeleyDB_DBEngine} = $BDBverStr;
            $Config{BerkeleyDB_DBEngine} = $BDBverStr;
        }
        $ConfigAdd{BerkeleyDB_DBEngine} = $BDBverStr;

        -d "$base/tmpDB" or mkdir "$base/tmpDB",0755;
        -d "$base/tmpDB/_cachecheck" or mkdir "$base/tmpDB/_cachecheck",0755;
        my $cd = "$base/tmpDB/_cachecheck";
        my $BDBEnv;
        unlink "$cd/__db.001";
        unlink "$cd/__db.002";
        unlink "$cd/__db.003";
        unlink "$cd/__db.004";
        unlink "$cd/BDB-cachesize-test-error.txt";
        my $F;
        while ($BDBMaxCacheSize) {
            unless (open ($F ,'>>', "$cd/BDB-cachesize-test-error.txt")) {
                mlog(0,"error: unable to open file $cd/BDB-cachesize-test-error.txt for writing - $!");
                $BDBMaxCacheSize = 0;
                last;
            }
            binmode $F;
            print $F &timestring()."\n";
            print $F "BDB cachesize test for $BDBMaxCacheSize MB\n";
            eval (<<'EOT');
            $BDBEnv = BerkeleyDB::Env->new(-Flags => DB_INIT_CDB | DB_CREATE | DB_INIT_MPOOL,
                                           -Cachesize => ($BDBMaxCacheSize * 1024 * 1024),
                                           -Home    => "$cd",
                                           -ErrFile => $F,
                                           -Config  => {DB_DATA_DIR => "$cd",
                                                        DB_LOG_DIR  => "$cd",
                                                        DB_TMP_DIR  => "$cd"}
                                          );
EOT
            if ($@ or $BerkeleyDB::Error !~ /: 0\s*$/o) {
                undef $BDBEnv;
                unlink "$cd/__db.001";
                unlink "$cd/__db.002";
                unlink "$cd/__db.003";
                unlink "$cd/__db.004";
                $BDBMaxCacheSize -= 100;
                print $F "\n\n";
                eval { $F->close; };
                next;
            }
            print $F "OK\n\n";
            eval { $F->close; };
            last;
        }
        $BDBMaxCacheSize ||= 50;
        mlog(0,"BerkeleyDB maximum cache size is set to ".formatDataSize($BDBMaxCacheSize * 1024 * 1024)) if $BDBMaxCacheSize;
        $BDBMaxCacheSize *= 1024 * 1024;
        undef $BDBEnv;
        unlink "$cd/__db.001";
        unlink "$cd/__db.002";
        unlink "$cd/__db.003";
        unlink "$cd/__db.004";
    }
  } elsif (!$AvailBerkeleyDB ) {
    $installed = $useBerkeleyDB ? 'is not installed' : 'is disabled in config';
    mlog(0,"BerkeleyDB module $installed - Berkeley database usage not available");
    $ModuleStat{'BerkeleyDB_DBEngine'} = 'status unknown';
    $Config{clearBerkeleyDBEnv} = 1;
    $runHMMusesBDB = 0;
  }
  $ModuleList{'BerkeleyDB'} = $VerBerkeleyDB.'/0.42';
  $ModuleStat{'BerkeleyDB'} = $installed;
  $ModuleList{'BerkeleyDB_DBEngine'} = $BDBver.'/4.5';
  print '.';

  if ($griplist) {
      if ($CanUseBerkeleyDB && $useDB4griplist) {
          $GriplistDriver = 'BerkeleyDB::Hash';
          $GriplistFile = "$base/$griplist.bdb";
          mlog(0,"info: griplist is using 'BerkeleyDB' version $BerkeleyDB::db_version in file $base/$griplist.bdb");
          if (! -e $GriplistFile) {
              unlink "$base/$griplist.bin";
          }
      } else {
          $GriplistDriver = 'orderedtie';
          $GriplistFile = "$base/$griplist";
          mlog(0,"info: griplist is using basic 'orderedtie' in file $base/$griplist");
      }
  }

  if (! $CanUseBerkeleyDB || ! $useDB4IntCache) {
      foreach (sort keys %tempDBvars) {
          next if $_ eq 'BackDNS2';
          share(%{$_});
      }
  }
  print '.';

  if ($CanUseCIDRlite) {
    $ver=eval('Net::CIDR::Lite->VERSION'); $VerNetCIDRLite=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Net::CIDR::Lite module$ver installed - hyphenated IP address range available");
    $installed = 'enabled';
  } elsif (!$AvailCIDRlite) {
    $installed = $useNetCIDRLite ? 'is not installed' : 'is disabled in config';
    mlog(0,"Net::CIDR::Lite module $installed - hyphenated IP address range not available");
  }
  $ModuleList{'Net::CIDR::Lite'} = $VerNetCIDRLite.'/0.20';
  $ModuleStat{'Net::CIDR::Lite'} = $installed;

  if ($CanUseNetAddrIPLite) {
    $ver=eval('NetAddr::IP::Lite->VERSION'); $VerNetAddrIPLite=$ver; $ver=" version $ver" if $ver;
    mlog(0,"NetAddr::IP::Lite module$ver installed - hyphenated IP and CIDR address range calculation available");
    $installed = 'enabled';
  } elsif (!$AvailNetAddrIPLite) {
    $installed = $useNetAddrIPLite ? 'is not installed' : 'is disabled in config';
    mlog(0,"NetAddr::IP::Lite module $installed - hyphenated IP and CIDR address range calculation not available");
  }
  $ModuleList{'NetAddr::IP::Lite'} = $VerNetAddrIPLite.'/1.47';
  $ModuleStat{'NetAddr::IP::Lite'} = $installed;

  if ($CanUseNetIP) {
    $ver=eval('Net::IP->VERSION'); $VerNetIP=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Net::IP module$ver installed - hyphenated IP and CIDR address range calculation available");
    $installed = 'enabled';
  } elsif (!$AvailNetIP) {
    $installed = $useNetIP ? 'is not installed' : 'is disabled in config';
    mlog(0,"Net::IP module $installed - hyphenated IP and CIDR address range calculation not available");
  }
  $ModuleList{'Net::IP'} = $VerNetAddrIPLite.'/1.26';
  $ModuleStat{'Net::IP'} = $installed;

  if ($CanUseLWP) {
    $ver=eval('LWP::Simple->VERSION'); $VerLWPSimple=$ver; $ver=" version $ver" if $ver;
    mlog(0,"LWP::Simple module$ver installed - procedural LWP interface available");
    $installed = 'enabled';
  } elsif (!$AvailLWP) {
    $installed = $useLWPSimple ? 'is not installed' : 'is disabled in config';
    mlog(0,"LWP::Simple module $installed - procedural LWP interface not available");
  }
  $ModuleList{'LWP::Simple'} = $VerLWPSimple.'/1.41';
  $ModuleStat{'LWP::Simple'} = $installed;

  if ($CanUseEMM) {
    $ver=eval('Email::MIME->VERSION'); $VerEmailMIME=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Email::MIME module$ver installed - MIME charset decoding and conversion interface and attachment detection available");
    $installed = 'enabled';
    $org_Email_MIME_parts_multipart = *{'Email::MIME::parts_multipart'};
    *{'Email::MIME::parts_multipart'} = *{'main::parts_multipart'};
    *{'Email::MIME::ContentType::_extract_ct_attribute_value'} = *{'assp_extract_ct_attribute_value'};
    *{'Email::MIME::ContentType::_parse_attributes'} = *{'assp_parse_attributes'};
  } elsif (!$AvailEMM) {
    $installed = $useEmailMIME ? 'is not installed' : 'is disabled in config';
    mlog(0,"Email::MIME module $installed - MIME charset decoding and conversion interface and attachment detection not available");
  }
  $ModuleList{'Email::MIME'} = $VerEmailMIME.'/1.442';
  $ModuleStat{'Email::MIME'} = $installed;

  if ($CanUseMTY) {
    $ver=eval('MIME::Types->VERSION'); $VerMIMETypes=$ver; $ver=" version $ver" if $ver;
    mlog(0,"MIME::Types module$ver installed - TNEF conversion may possible");
    $installed = 'enabled';
  } elsif (!$AvailMTY) {
    $installed = $useMIMETypes ? 'is not installed' : 'is disabled in config';
    mlog(0,"MIME::Types module $installed - TNEF conversion not available");
  }
  $ModuleList{'MIME::Types'} = $VerMIMETypes.'/1.23';
  $ModuleStat{'MIME::Types'} = $installed;
  print '.';

  if ($CanUseEMS) {
    $ver=eval('Email::Send->VERSION'); $VerEmailSend=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Email::Send module$ver installed - sending .eml files available");
    $installed = 'enabled';
  } elsif (!$AvailEMS) {
    $installed = $useEmailSend ? 'is not installed' : 'is disabled in config';
    mlog(0,"Email::Send module $installed - sending .eml files is not available");
  }
  $ModuleList{'Email::Send'} = $VerEmailSend.'/2.192';
  $ModuleStat{'Email::Send'} = $installed;

  if ($CanUseTNEF) {
    $ver=eval('Convert::TNEF->VERSION'); $VerConvertTNEF=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Convert::TNEF module$ver installed - TNEF conversion is available");
    $installed = 'enabled';
  } elsif (!$AvailTNEF)  {
    $installed = $useConvertTNEF ? 'is not installed' : 'is disabled in config';
    mlog(0,"Convert::TNEF module $installed - TNEF conversion not available");
  }
  $ModuleList{'Convert::TNEF'} = $VerConvertTNEF.'/0.17';
  $ModuleStat{'Convert::TNEF'} = $installed;

  if ($CanUseDKIM) {
    $ver=eval('Mail::DKIM::Verifier->VERSION'); $VerMailDKIMVerifier=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Mail::DKIM::Verifier module$ver installed - DKIM verification is available");
    $installed = 'enabled';
    if ($ver lt '0.40') {   # the multiple DNS resolver issue is fixed in 0.40
        *{'Mail::DKIM::DNS::query'} = *{'main::DKIM_DNS_query'};
        *{'Mail::DKIM::DNS::query_async'} = *{'main::DKIM_DNS_query_async'};
    }
  } elsif (!$AvailDKIM)  {
    $installed = $useMailDKIMVerifier ? 'is not installed' : 'is disabled in config';
    mlog(0,"Mail::DKIM::Verifier module $installed - DKIM verification not available");
  }
  $ModuleList{'Mail::DKIM::Verifier'} = $VerMailDKIMVerifier.'/0.37';
  $ModuleStat{'Mail::DKIM::Verifier'} = $installed;

  if ($CanUseSchedCron) {
    $ver=eval('Schedule::Cron->VERSION'); $VerScheduleCron=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Schedule::Cron module$ver installed - RebuildSpamdb Scheduler is available");
    $installed = 'enabled';
  } elsif (!$AvailSchedCron)  {
    $installed = $useScheduleCron ? 'is not installed' : 'is disabled in config';
    mlog(0,"Schedule::Cron module $installed - RebuildSpamdb Scheduler not available");
  }
  $ModuleList{'Schedule::Cron'} = $VerScheduleCron.'/0.97';
  $ModuleStat{'Schedule::Cron'} = $installed;

  if ($CanUseSysMemInfo) {
    $ver=eval('Sys::MemInfo->VERSION'); $VerSysMemInfo=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Sys::MemInfo module$ver installed - memory calculation is available");
    $installed = 'enabled';
  } elsif (!$AvailSysMemInfo)  {
    $installed = $useSysMemInfo ? 'is not installed' : 'is disabled in config';
    mlog(0,"Sys::MemInfo module $installed - memory calculation not available");
  }
  $ModuleList{'Sys::MemInfo'} = $VerSysMemInfo.'/0.91';
  $ModuleStat{'Sys::MemInfo'} = $installed;

  if ($CanUseSysCpuAffinity) {
    $ver=eval('Sys::CpuAffinity->VERSION'); $VerSysCpuAffinity=$ver; $ver=" version $ver" if $ver;
    eval{$numcpus = Sys::CpuAffinity::getNumCpus();};
    $numcpus ||= 'an undected number of';
    mlog(0,"Sys::CpuAffinity module$ver installed - setting CPU Affinty is available - this system has $numcpus CPU\'s");
    eval{@currentCpuAffinity = Sys::CpuAffinity::getAffinity($$)};
    mlog(0,"The Cpu Affinity of assp is currently '@currentCpuAffinity'");
    $installed = 'enabled';
  } elsif (!$AvailSysCpuAffinity)  {
    $installed = $useSysCpuAffinity ? 'is not installed' : 'is disabled in config';
    mlog(0,"Sys::CpuAffinity module $installed - setting CPU Affinty not available");
  }
  $ModuleList{'Sys::CpuAffinity'} = $VerSysCpuAffinity.'/1.05';
  $ModuleStat{'Sys::CpuAffinity'} = $installed;

  print '.';

  if ($CanUseAuthenSASL) {
    $ver=eval('Authen::SASL->VERSION'); $VerAuthenSASL=$ver; $ver=" version $ver" if $ver;
    mlog(0,"Authen::SASL module$ver installed - SMTP AUTH is available");
    $installed = 'enabled';
  } elsif (!$AvailAuthenSASL)  {
    $installed = $useAuthenSASL ? 'is not installed' : 'is disabled in config';
    mlog(0,"Authen::SASL module $installed - SMTP AUTH is not available");
  }
  $ModuleList{'Authen::SASL'} = $VerAuthenSASL.'/2.1401';
  $ModuleStat{'Authen::SASL'} = $installed;

  if ($CanUseRegexpOptimizer) {
    $ver=eval('Regexp::Optimizer->VERSION'); $VerRegexpOptimizer=$ver; $ver=" version $ver" if $ver;
    if ($VerRegexpOptimizer ge '0.23') {
        mlog(0,"Regexp::Optimizer module$ver installed - default Regular Expression Optimization is available");
        $installed = 'enabled';
    } else {
        $CanUseRegexpOptimizer = $AvailRegexpOptimizer = 0;
        $installed = "with wrong version ($VerRegexpOptimizer) installed (requires 0.23)";
        mlog(0,"Regexp::Optimizer module $installed - default Regular Expression Optimization is not available - regex processing will take approximately 3 times longer");
    }
  } elsif (!$AvailRegexpOptimizer)  {
    $installed = $useRegexpOptimizer ? 'is not installed' : 'is disabled in config';
    mlog(0,"Regexp::Optimizer module $installed - default Regular Expression Optimization is not available - regex processing will take  approximately 3 times longer");
  }
  $ModuleList{'Regexp::Optimizer'} = $VerRegexpOptimizer.'/0.23';
  $ModuleStat{'Regexp::Optimizer'} = $installed;

  if ($CanUseAsspSelfLoader) {
    $ver=eval('AsspSelfLoader->VERSION'); $VerAsspSelfLoader=$ver; $ver=" version $ver" if $ver;
    mlog(0,"AsspSelfLoader module$ver installed - SPAMBOX Code Load Optimization is available");
    $installed = 'enabled';
  } elsif (!$AvailAsspSelfLoader)  {
    $installed = $useAsspSelfLoader ? 'is not installed' : 'is disabled in config';
    mlog(0,"AsspSelfLoader module $installed - SPAMBOX Code Load Optimization is not available");
  }
  $ModuleList{'AsspSelfLoader'} = $VerAsspSelfLoader.'/'.$requiredSelfLoaderVersion;
  $ModuleStat{'AsspSelfLoader'} = $installed;

  if ($CanUseSPAMBOX_WordStem) {
    $ver=eval('SPAMBOX_WordStem->VERSION'); $VerSPAMBOX_WordStem=$ver; $ver=" version $ver" if $ver;
    mlog(0,"SPAMBOX_WordStem module$ver installed - SPAMBOX multi lingual word stemming engine for Bayesian and HMM checks is available");
    $installed = 'enabled';
    $requiredDBVersion{'Spamdb'} .= "_WordStem$VerSPAMBOX_WordStem";
    $requiredDBVersion{'HMMdb'}  .= "_WordStem$VerSPAMBOX_WordStem";
    # make Lingua::Stem::Snowball thread safe if it is'nt
    if (! defined *{'Lingua::Stem::Snowball::CLONE_SKIP'}) {
        *{'Lingua::Stem::Snowball::CLONE_SKIP'} = *{'main::Stem_Clone_Skip'};
    }
    if (! defined *{'Lingua::Stem::Snowball::CLONE'}) {
        *{'Lingua::Stem::Snowball::CLONE'} = *{'main::Stem_Clone'};
    }
  } elsif (!$AvailSPAMBOX_WordStem)  {
    $installed = $useSPAMBOX_WordStem ? 'is not installed' : 'is disabled in config';
    mlog(0,"SPAMBOX_WordStem module $installed - SPAMBOX multi lingual word stemming engine for Bayesian and HMM checks is not available");
  }
  $ModuleList{'SPAMBOX_WordStem'} = $VerSPAMBOX_WordStem.'/1.24';
  $ModuleStat{'SPAMBOX_WordStem'} = $installed;

  if ($CanUseSPAMBOX_FC) {
    $ver=eval('SPAMBOX_FC->VERSION'); $VerSPAMBOX_FC=$ver; $ver=" version $ver" if $ver;
    mlog(0,"SPAMBOX_FC module$ver installed - SPAMBOX file commander is available");
    $installed = 'enabled';
  } elsif (!$AvailSPAMBOX_FC)  {
    $installed = $useSPAMBOX_FC ? 'is not installed' : 'is disabled in config';
    mlog(0,"SPAMBOX_FC module $installed - SPAMBOX file commander is not available");
  }
  $ModuleList{'SPAMBOX_FC'} = $VerSPAMBOX_FC.'/1.05';
  $ModuleStat{'SPAMBOX_FC'} = $installed;

  if ($CanUseSPAMBOX_SVG) {
    $ver=eval('SPAMBOX_SVG->VERSION'); $VerSPAMBOX_SVG=$ver; $ver=" version $ver" if $ver;
    mlog(0,"SPAMBOX_SVG module$ver installed - SPAMBOX graphical STATS are available");
    $installed = 'enabled';
  } elsif (!$AvailSPAMBOX_SVG)  {
    $installed = $useSPAMBOX_SVG ? 'is not installed' : 'is disabled in config';
    mlog(0,"SPAMBOX_SVG module $installed - SPAMBOX graphical STATS are not available");
  }
  $ModuleList{'SPAMBOX_SVG'} = $VerSPAMBOX_SVG.'/1.03';
  $ModuleStat{'SPAMBOX_SVG'} = $installed;

  if ($CanUseIOSocketSSL) {
    $ver=eval('IO::Socket::SSL->VERSION'); $VerIOSocketSSL=$ver; $ver=" version $ver" if $ver;
    mlog(0,"IO::Socket::SSL module$ver installed - https and TLS/SSL is possible");
    mlog(0,"IO::Socket::SSL module$ver installed - but at least version 1.32 is recommended")
        if ($VerIOSocketSSL < '1.32');
    $installed = 'enabled';
    $ModuleList{'Net::SSLeay'} = (eval('Net::SSLeay->VERSION')).'/1.35';
    $ModuleStat{'Net::SSLeay'} = $installed;
# IO-Socket-IP is not what IO-Socket-SSL should use - what a HACK ???
    if ("@IO::Socket::SSL::ISA" eq 'IO::Socket::IP') {
        undef &IO::Socket::SSL::CAN_IPV6;
        if ($CanUseIOSocketINET6) {
            @IO::Socket::SSL::ISA = 'IO::Socket::INET6';
            $IO::Socket::SSL::IOCLASS = 'IO::Socket::INET6';
            *{IO::Socket::SSL::CAN_IPV6} = sub {'IO::Socket::INET6';};
        } else {
            @IO::Socket::SSL::ISA = 'IO::Socket::INET';
            $IO::Socket::SSL::IOCLASS = 'IO::Socket::INET';
            *{IO::Socket::SSL::CAN_IPV6} = sub {'';};
        }
    }
    if (-e $SSLCertFile and -e $SSLKeyFile) {
        mlog(0,'found valid certificate and private key file - https and TLS/SSL is available');
        mlog(0,'found valid ca file - chained certificate validation is available') if $SSLCaFile && -e $SSLCaFile;
        my $d = Net::SSLeay::CTX_new();   # initialize Net::SSLeay before threads are started
    } else {
        if (system('openssl', 'version') == 0) {
            mlog(0,'info: openssl is installed - try to create basic SSL-certificates');
            &genCerts;
        } else {
            mlog(0,'info: openssl is not installed on this system - unable to create basic certificates');
        }
        if (-e $SSLCertFile and -e $SSLKeyFile) {
            mlog(0,'found valid certificate and private key file - https and TLS/SSL is available');
            mlog(0,'found valid ca file - chained certificate validation is available') if $SSLCaFile && -e $SSLCaFile;
            my $d = Net::SSLeay::CTX_new();   # initialize Net::SSLeay before threads are started
        } else {
            $CanUseIOSocketSSL = 0;
            mlog(0,"warning: server certificate $SSLCertFile not found") unless (-e $SSLCertFile);
            mlog(0,"warning: server public-key $SSLKeyFile not found") unless (-e $SSLKeyFile);
            mlog(0,'warning: https and TLS/SSL is disabled');
            $installed = 'no certificate found';
        }
    }
  } elsif (!$AvailIOSocketSSL)  {
    $installed = $useIOSocketSSL ? 'is not installed' : 'is disabled in config';
    mlog(0,"IO::Socket::SSL module $installed - https and TLS/SSL not available");
  }
  $ModuleList{'IO::Socket::SSL'} = $VerIOSocketSSL.'/1.32';
  $ModuleStat{'IO::Socket::SSL'} = $installed;

  my $v;
  $ModuleList{'Plugins::SPAMBOX_AFC'}   =~ s/([0-9\.\-\_]+)$/$v=3.10;$1>$v?$1:$v;/oe if exists $ModuleList{'Plugins::SPAMBOX_AFC'};
  $ModuleList{'Plugins::SPAMBOX_ARC'}   =~ s/([0-9\.\-\_]+)$/$v=2.05;$1>$v?$1:$v;/oe if exists $ModuleList{'Plugins::SPAMBOX_ARC'};
  $ModuleList{'Plugins::SPAMBOX_DCC'}   =~ s/([0-9\.\-\_]+)$/$v=2.01;$1>$v?$1:$v;/oe if exists $ModuleList{'Plugins::SPAMBOX_DCC'};
  $ModuleList{'Plugins::SPAMBOX_OCR'}   =~ s/([0-9\.\-\_]+)$/$v=2.18;$1>$v?$1:$v;/oe if exists $ModuleList{'Plugins::SPAMBOX_OCR'};
  $ModuleList{'Plugins::SPAMBOX_Razor'} =~ s/([0-9\.\-\_]+)$/$v=1.09;$1>$v?$1:$v;/oe if exists $ModuleList{'Plugins::SPAMBOX_Razor'};

  if (scalar keys %ModuleError) {
      mlog(0,"warning: There were module load errors detected - look in to file $base/moduleLoadErrors.txt for more details. To solve this issue install the failed modules or disable them in the 'Module Setup' section in the GUI.");
  }
  print '.';

  mlog(0,"warning: RelayOnlyLocalSender nor RelayOnlyLocalDomains is enabled!") if (!($RelayOnlyLocalSender || $RelayOnlyLocalDomains) && ! $nolocalDomains);
  mlog(0,"warning: DoLocalSenderAddress nor DoLocalSenderDomain is enabled!") if (!($DoLocalSenderAddress || $DoLocalSenderDomain) && ! $nolocalDomains);

  $tThreadHandler{1} = \&NewSMTPConnectionConnect;     # set subs to numbers / subs-refs can not be shared
  $tThreadHandler{2} = \&NewProxyConnection;    # so the tread will know what to do

# are we using any database tables?
  $DBisUsed = 0;
  for my $idx (0...$#ConfigArray) {
    my $c = $ConfigArray[$idx];
    if ($Config{$c->[0]}=~/DB:/o && ($CanUseTieRDBM or $CanUseBerkeleyDB)) {
      $DBisUsed = 1;
      last;
    }
  }

  $nextNoop=time;
  $endtime=$nextNoop+$RestartEvery;

  loadHashFromFile( "$base/scheduleHistory", \%LastSchedRun );
  ScheduleMapSet();
  $NextSaveStats = max($NextSaveStats, (time + 300));

  if ($backupDBInterval && ! isSched($backupDBInterval) && $backupDBDir && -d "$base/$backupDBDir") {
    my $mtime = ftime("$base/$backupDBDir");
    if ($mtime) {
        my $m = &getTimeDiff(time - $mtime);
        mlog(0,"info: last DB-backup was scheduled before $m") if ($DBisUsed && $MaintenanceLog);
        $nextDBBackup=$mtime+$backupDBInterval*3600;
        $nextDBBackup = time + 300 if ($nextDBBackup - time < 300);
        $m = &getTimeDiff($nextDBBackup - time);
        mlog(0,"info: next DB-backup is scheduled in $m") if ($DBisUsed && $MaintenanceLog);
    }
  }
  $nextDBcheck=$nextNoop+30; # check DB connection every 30 seconds
  $nextThreadsWakeUp=$nextNoop+$ThreadsWakeUpInterval;
  $nextCleanBATVTag=$nextNoop + 3600;
  $nextConSync = $nextNoop + 60;
  $nextResendMail = $nextNoop + 300;
  $nextRebuildSpamDB = isSched($RebuildSchedule) ? getSchedTime('RebuildSchedule') : 0;
  $nextDNSCheck = $nextNoop + 60;
  $lastDNScheck = 0;
  $nextCleanIPDom = $nextNoop + 300;
  $nextBDBsync = $nextNoop + 900;
  $nextdetectHourJob = int($nextNoop / 3600) * 3600 + 3600;
  $nextdetectHourJob += 15 unless ($nextdetectHourJob + TimeZoneDiff()) % (24 * 3600);
  my $m = &getTimeDiff($nextdetectHourJob-$nextNoop);
  mlog(0,"info: hourly scheduler is starting in $m") if $MaintenanceLog >=2;

  chmod 0755, "$base/spambox.cfg";

  my $liccount = 0;
  -d "$base/license" or mkdir "$base/license",0755;
  if (-r "$base/license/assp.license") {
      local $/ = undef;
      open(my $F, '<',"$base/license/assp.license");binmode($F);$T[0] = <$F>;close $F;
      if (eval{$T[0] && $L->($T[0])}) {
          $liccount++;
      } else {
          @T = ();
          mlog(0,"warning: license file '$base/license/assp.license' is not valid - use internal license");
      }
  }
  unless ($T[0] && eval{$L->($T[0])}) {
      $T[0] = ($Y->{useXS}) ? <<'EOT1' : <<'EOT2';
3D27BEF787EEB4C6D2A40968821CFF93E451284854277EE02CA6F5D418F4E020F35B3F6D169E7398BDCE4C14D3EDAAA5B6D9FA8986A7C5B0372EA8AC
14CDABEF52A96235E3A6A1727A42FC95C94F9B922F1A7C355F7CCAFE9F2526AA138637A545060D019E3F988DE88B8020317E6D6BD337656ACAA3DE93
6C95EAAAA6A41E54E0DB51D472A26FFE63650D4037B1C24914EA3FEEBB2CBCB9E3E46AC6A67E6A014A36C18AE5F31888B067DE1CE47263D9BAA70D59
CD6BC5CD975801F173EA6C603E6CE6A73D7D078EBAE6BD993B35766419BCF99C9B9D2D24BE1E3FF0A578C1F899EB394AFEA9E419EB46FDF86205B8F9
3F26129B75990B77A310FD5D62E87DF8E8390AA47817C1ADFA802B2AFAD0D801
01104440EE
EOT1
CF47405B197EEBE265A94D35A79E0B312A9A0CFEA865961B7267838437B765D98EC1EBFC8FA82427A6BBC369C6408FCF742CB72E0046573C042DC5F6
AD52FD93155B368A9855ED760672210B7DCF5EA8D78CCE3BCBDC902CE68764C6E0EE355AC0185577F958A995D6518880E3E950945A1DEC58CD551B66
445BA826D30BC729E87CB15EDFAA39E14F8B56923984F3015C896A948134D436EA578E8A036672A511E858BE1A544180EC483B120C7AE55B21B88518
B12698FFA78AD88F26D6D66C497A6FD019EDB954276ED5521D423A4F2C0D1A276F41EBB5238911D22167BFB1C496A2B2005638E86FFC929CF0C26028
D641F65423B12D76CAE8414EB71AB843775EB09C6D39015BEA12A0427870E62A
01104440EE
EOT2
      $T[0] =~ s/\r|\n|\s//gos;
      $T[0] =~ s/([0-9a-fA-F]{2})/pack('C',hex($1))/geo;
      if (eval{$T[0] && $L->($T[0])}) {
          $liccount++;
      } else {
          @T = ();
          mlog(0,"error: internal public license is not valid");
      }
  }
  if ($liccount) {
      for ( Glob("$base/license/*.license") ) {
          next if /\/assp.license$/oi;
          local $/ = undef;
          open(my $F, '<',"$_");binmode($F);my $f = <$F>;close $F;
          unless (eval{$f && $L->($f)}) {
              mlog(0,"warning: license file '$_' is not valid");
              next;
          }
          foreach my $s (keys(%{$L->($f)->{license}})) {
              next unless $s;
              next unless int($s);
              $liccount++;
              $T[int($s)] = $f;
          }
      }
  }
  mlog(0,'info: '.needEs($liccount,' license','s').' registered');

  print "\t\t\t\t[OK]\nchecking directories";
# create folders if they're missing
  -d "$base/$spamlog" or mkdir "$base/$spamlog",0755;
  -d "$base/$notspamlog" or mkdir "$base/$notspamlog",0755;
  -d "$base/$incomingOkMail" or mkdir "$base/$incomingOkMail", 0755;
  -d "$base/$discarded"  or mkdir "$base/$discarded",  0755;
  -d "$base/files" or mkdir "$base/files",0755;
  -d "$base/logs" or mkdir "$base/logs",0755;
  
  -d "$base/rebuild_error" or mkdir "$base/rebuild_error", 0755;
  -d "$base/rebuild_error/$spamlog" or mkdir "$base/rebuild_error/$spamlog", 0755;
  -d "$base/rebuild_error/$notspamlog" or mkdir "$base/rebuild_error/$notspamlog", 0755;

  my $dir=$correctedspam;
  $dir=~s/\/.*?$//o;
  -d "$base/$dir" or mkdir "$base/$dir",0755;
  -d "$base/$correctedspam" or mkdir "$base/$correctedspam",0755;
  -d "$base/$correctedspam/newManualyAdded" and rmdir("$base/$correctedspam/newManualyAdded");
  -d "$base/$correctedspam/newManuallyAdded" or mkdir "$base/$correctedspam/newManuallyAdded",0755;
  -d "$base/rebuild_error/$dir" or mkdir "$base/rebuild_error/$dir", 0755;
  -d "$base/rebuild_error/$correctedspam" or mkdir "$base/rebuild_error/$correctedspam", 0755;
  $dir=$correctednotspam;
  $dir=~s/\/.*?$//o;
  -d "$base/$dir" or mkdir "$base/$dir",0755;
  -d "$base/$correctednotspam" or mkdir "$base/$correctednotspam",0755;
  -d "$base/$correctednotspam/newManualyAdded" and rmdir("$base/$correctednotspam/newManualyAdded");
  -d "$base/$correctednotspam/newManuallyAdded" or mkdir "$base/$correctednotspam/newManuallyAdded",0755;
  -d "$base/rebuild_error/$dir" or mkdir "$base/rebuild_error/$dir", 0755;
  -d "$base/rebuild_error/$correctednotspam" or mkdir "$base/rebuild_error/$correctednotspam", 0755;

  -d "$base/$resendmail" or mkdir "$base/$resendmail",0755;
  $pbdir = $1 if $pbdb=~/(.*)\/.*/o;
  $pbdir = 'pb' if $pbdb =~ /DB:/o;
  if ($pbdir) {
     -d  "$base/$pbdir" or mkdir "$base/$pbdir",0755;
     -d  "$base/$pbdir/global" or mkdir "$base/$pbdir/global",0755;
     -d  "$base/$pbdir/global/in" or mkdir "$base/$pbdir/global/in",0755;
     -d  "$base/$pbdir/global/out" or mkdir "$base/$pbdir/global/out",0755;
  }
  -d "$base/notes" or mkdir "$base/notes",0755;
  -d "$base/docs" or mkdir "$base/docs",0755;
  my $mysqldir; $mysqldir = $1 if $importDBDir=~/(.*)\/.*/o;
  mkdir "$base/$mysqldir",0755 if $mysqldir;
  -d "$base/$importDBDir" or mkdir "$base/$importDBDir",0755;
  $mysqldir = $1 if $exportDBDir=~/(.*)\/.*/o;
  mkdir "$base/$mysqldir",0755 if $mysqldir;
  -d "$base/$exportDBDir" or mkdir "$base/$exportDBDir",0755;
  $mysqldir = $1 if $backupDBDir=~/(.*)\/.*/o;
  mkdir "$base/$mysqldir",0755 if $mysqldir;
  -d "$base/$backupDBDir" or mkdir "$base/$backupDBDir",0755;
  -d "$base/dkim" or mkdir "$base/dkim",0755;
  -d "$FileScanDir" or mkdir "$FileScanDir",0755;
  -d "$base/Plugins" or mkdir "$base/Plugins",0777;
  -d "$base/tmp" or mkdir "$base/tmp",0755;
  -d "$base/tmpDB" or mkdir "$base/tmpDB",0755;
  -d "$base/crash_repo" or mkdir "$base/crash_repo",0755;
  -d "$base/debug" or mkdir "$base/debug",0755;

  foreach my $file ( Glob("$base/tmp/*")) {
      mlog(0,"info: deleted temporary file $file") if unlink($file) && $MaintenanceLog > 1;
  }

  my $unclean = (exists $Config{clearBerkeleyDBEnv} || -e "$base/$pidfile");
  mlog(0,'error: unclean shutdown of SPAMBOX detected') if $unclean;
  foreach my $dir ( Glob("$base/tmpDB/*")) {
      if (-d $dir) {
          my $del;
          foreach my $f ( Glob("$dir/*")) {
             if ($f =~ /\.00\d$/o) {
                 $del = 1;
                 unlink($f) || mlog(0,"error: unable to cleanup $f - $!");
             } elsif ($f =~ /\.bdb$/io && ($f !~ /BackDNS2|rebuildDB/o || $unclean) ) {
                 $del = 1;
                 unlink($f) || mlog(0,"error: unable to cleanup $f - $!");
             }
          }
          mlog(0,"info: cleaned temporary BerkeleyDB directory $dir") if $del && $unclean;
      }
  }
  if ($useDB4griplist && $unclean) {
      foreach ( Glob("$base/griplist.*")) {
          next if (-d "$_");
          mlog(0,"info: removed GRIPLIST file $_") if unlink($_);
      }
  }
  delete $Config{clearBerkeleyDBEnv};
  &SaveConfig() if $unclean;

  if($pidfile) {open(my $PIDH,'>',"$base/$pidfile"); $PIDH->autoflush; print $PIDH $$; close $PIDH}

  if ($^O ne 'MSWin32') {
      if($setFilePermOnStart) {
          print "\t\t\t\t\t[OK]\nsetup file permission" ;
          &setPermission($base,oct('0777'),1,1) ;
          $Config{setFilePermOnStart} = '';
          $setFilePermOnStart = '';
          &SaveConfig();
      } elsif ($checkFilePermOnStart) {
          print "\t\t\t\t\t[OK]\ncheck file permission" ;
          &checkPermission($base,oct('0600'),1,1) ;
      }
  } else {
      if($setFilePermOnStart) {
          print "\t\t\t\t\t[OK]\nskip file permission" ;
          $Config{setFilePermOnStart} = $setFilePermOnStart = '';
      } elsif ($checkFilePermOnStart) {
          print "\t\t\t\t\t[OK]\nskip file permission" ;
          $Config{checkFilePermOnStart} = $checkFilePermOnStart = '';
      }
  }

  $nextGlobalUploadBlack = $nextNoop + 120;
  $nextGlobalUploadWhite = $nextNoop + 120;
  if (-e "$base/$pbdir/global/out/pbdb.black.db.gz") {
    my $mtime = ftime("$base/$pbdir/global/out/pbdb.black.db.gz");
    my $m = &getTimeDiff(time - $mtime);
    mlog(0,"info: last PBBlack upload to global server was scheduled before $m") if (($DoGlobalBlack || $GPBDownloadLists || $GPBautoLibUpdate) && $globalClientName && $globalClientPass && $MaintenanceLog);
    if ($mtime) {
        $nextGlobalUploadBlack=$mtime + (int(rand(300) + 1440))*60;
        my $m = &getTimeDiff($nextGlobalUploadBlack - time);
        mlog(0,"info: next PBBlack upload to global server is scheduled in $m") if (($DoGlobalBlack || $GPBDownloadLists || $GPBautoLibUpdate) && $globalClientName && $globalClientPass && $MaintenanceLog);
    }
  }
  if (-e "$base/$pbdir/global/out/pbdb.white.db.gz") {
    my $mtime = ftime("$base/$pbdir/global/out/pbdb.white.db.gz");
    my $m = &getTimeDiff(time - $mtime);
    mlog(0,"info: last PBWhite upload to global server was scheduled before $m") if (($DoGlobalWhite || $GPBDownloadLists || $GPBautoLibUpdate) && $globalClientName && $globalClientPass && $MaintenanceLog);
    if ($mtime) {
        $nextGlobalUploadWhite=$mtime + (int(rand(300) + 1440))*60 if ($mtime);
        my $m = &getTimeDiff($nextGlobalUploadWhite - time);
        mlog(0,"info: next PBWhite upload to global server is scheduled in $m") if (($DoGlobalWhite || $GPBDownloadLists || $GPBautoLibUpdate) && $globalClientName && $globalClientPass && $MaintenanceLog);
    }
  }

 # is any database driver defined - so we have to parse the driver and the options
  if ($DBdriver && ($CanUseTieRDBM or $CanUseBerkeleyDB)) {
    @DBdriverdef = split(/,/o,$DBdriver);
    $DBusedDriver = $DBdriverdef[0];
    $DBcntOption = @DBdriverdef;
    for (my $i=1;$i<$DBcntOption;$i++) {
      if ($DBusedDriver eq 'BerkeleyDB') {
          $DBOption.=',' if ($i > 1);
          $DBOption.="$DBdriverdef[$i]"  # putting all optons in to
      } else {
          $DBOption.=";$DBdriverdef[$i]"  # putting all optons in to
      }
      $DBautocommit = 0 if ($DBdriverdef[$i] =~ /^\s*autocommit\s*=>?\s*0\s*$/oi);
    }
    my $host = ($DBusedDriver eq 'ODBC' || $DBusedDriver eq 'ADO') ? 'server' : 'host';
    mlog(0,"info: the DBI connection string is set to: 'DBI:$DBusedDriver:database=$mydb;$host=$myhost$DBOption'") if ($DBusedDriver ne 'BerkeleyDB');
    if ($DBusedDriver eq 'BerkeleyDB') {
        $runHMMusesBDB = 0;
    } else {
        mlog(0,"info: 'autocommit' is switched off for the '$DBusedDriver' database driver") unless $DBautocommit;
    }
  }

#define Cache- and List groups - so have to care about only here
  @GroupList=("whitelistGroup","PersBlackGroup","redlistGroup","delayGroup","pbdbGroup","spamdbGroup","LDAPGroup","AdminGroup");
  my $HMMdb = 'HMMdb';
  if ($spamdb !~ /DB:/o && $spamdb =~ /^(.+?\/)[^\/]+$/o) {
      $HMMdb = $1 . $HMMdb;
  }
  my $v;
# $v =  "KeyName   ,dbConfigVar,CacheObject     ,realFileName  ,mysqlFileName,FailoverValue,mysqlTable"); remove spaces and push to Group
#                                                                                                         for dbConfigVar
  $v = ("Whitelist ,whitelistdb,WhitelistObject ,$whitelistdb  ,whitelist    ,whitelist  ,whitelist"   ); $v=~s/\s*,/,/go; push(@whitelistGroup,$v);

  $v = ("Redlist   ,redlistdb  ,RedlistObject   ,$redlistdb    ,redlist      ,redlist    ,redlist"     ); $v=~s/\s*,/,/go; push(@redlistGroup,$v);

  $v = ("Delay     ,delaydb    ,DelayObject     ,$delaydb      ,delaydb      ,delaydb    ,delaydb"     ); $v=~s/\s*,/,/go; push(@delayGroup,$v);
  $v = ("DelayWhite,delaydb    ,DelayWhiteObject,$delaydb.white,delaydb.white,delaydb    ,delaywhitedb"); $v=~s/\s*,/,/go; push(@delayGroup,$v);

  $v = ("Spamdb    ,spamdb     ,SpamdbObject    ,$spamdb       ,spamdb       ,spamdb     ,spamdb"      ); $v=~s/\s*,/,/go; push(@spamdbGroup,$v);
  $v = ("HeloBlack ,spamdb     ,HeloBlackObject ,$spamdb.helo  ,spamdb.helo  ,spamdb     ,spamdbhelo"  ); $v=~s/\s*,/,/go; push(@spamdbGroup,$v);

  if (! $runHMMusesBDB || ! $CanUseBerkeleyDB) {
      $v = ("HMMdb ,spamdb     ,HMMdbObject     ,$HMMdb        ,HMMdb        ,spamdb     ,hmmdb"      ); $v=~s/\s*,/,/go; push(@spamdbGroup,$v);
      delete $tempDBvars{HMMdb};
  }
  
  $v = ("PBWhite   ,pbdb       ,PBWhiteObject   ,$pbdb.white.db,pbdb.white.db,pb/pbdb    ,PBWhite"     ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("PBBlack   ,pbdb       ,PBBlackObject   ,$pbdb.black.db,pbdb.black.db,pb/pbdb    ,PBBlack"     ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("RBLCache  ,pbdb       ,RBLCacheObject  ,$pbdb.rbl.db  ,pbdb.rbl.db  ,pb/pbdb    ,RBLCache"    ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("URIBLCache,pbdb       ,URIBLCacheObject,$pbdb.uribl.db,pbdb.uribl.db,pb/pbdb    ,URIBLCache"  ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("PTRCache  ,pbdb       ,PTRCacheObject  ,$pbdb.ptr.db  ,pbdb.ptr.db  ,pb/pbdb    ,PTRCache"    ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("MXACache  ,pbdb       ,MXACacheObject  ,$pbdb.mxa.db  ,pbdb.mxa.db  ,pb/pbdb    ,MXACache"    ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("RWLCache  ,pbdb       ,RWLCacheObject  ,$pbdb.rwl.db  ,pbdb.rwl.db  ,pb/pbdb    ,RWLCache"    ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("SPFCache  ,pbdb       ,SPFCacheObject  ,$pbdb.spf.db  ,pbdb.spf.db  ,pb/pbdb    ,SPFCache"    ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("SBCache   ,pbdb       ,SBCacheObject   ,$pbdb.sb.db   ,pbdb.sb.db   ,pb/pbdb    ,SBCache"     ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("PBTrap    ,pbdb       ,PBTrapObject    ,$pbdb.trap.db ,pbdb.trap.db ,pb/pbdb    ,PBTrap"      ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("DKIMCache ,pbdb       ,DKIMCacheObject ,$pbdb.dkim.db ,pbdb.dkim.db ,pb/pbdb    ,DKIMCache"   ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("BATVTag   ,pbdb       ,BATVTagObject   ,$pbdb.batv.db ,pbdb.batv.db ,pb/pbdb    ,BATVTag"     ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);
  $v = ("BackDNS   ,pbdb       ,BackDNSObject   ,$pbdb.back.db ,pbdb.back.db ,pb/pbdb    ,BackDNS"     ); $v=~s/\s*,/,/go; push(@pbdbGroup,$v);

  $v = ("PersBlack ,persblackdb,PersBlackObject ,$persblackdb  ,persblack    ,persblack  ,persblack"   ); $v=~s/\s*,/,/go; push(@PersBlackGroup,$v);

  $v = ("LDAPlist  ,ldaplistdb ,LDAPlistObject  ,$ldaplistdb   ,ldaplist     ,ldaplist   ,ldaplist"    ); $v=~s/\s*,/,/go; push(@LDAPGroup,$v);

  $v = ("AdminUsers,adminusersdb ,AdminUsersObject,$adminusersdb   ,adminusers   ,adminusers ,AdminUsers"  ); $v=~s/\s*,/,/go; push(@AdminGroup,$v);
  $v = ("AdminUsersRight,adminusersdb,AdminUsersRightObject,$adminusersdb.right,adminusers.right,adminusers,AdminUsersRight"   ); $v=~s/\s*,/,/go; push(@AdminGroup,$v);
# %Types is defined by Tie::RDBM -> we redefine the datatypes for the key field of some drivers
# For better support of the key field with different charsets defined by the DB - the key field should
# be a varbinary type  -  some databases skipping leading and/or trailing spaces in char and varchar fields
# which cause in unexpected or missing keys in spamdb
# for MySQL the field value is redefined from longblob to varbinary(255) - so we can read the data in MySQL-Admin
# the length of the key field is set to 254 for all - to have one byte over for indexes (see Informix)
# the length of the value field is set to 255 for all - this is enough for SPAMBOX

if ($CanUseTieRDBM) {
# %Types is used for creating the data table if it doesn't exist already.
  %Tie::RDBM::Types = (   # key            value            frozen    freeze  keyless
	  'default' => [qw/ varbinary(254)  varbinary(255)   integer   0          0 /],  #others
	  'mysql'   => [qw/ varbinary(254)  varbinary(255)   tinyint   1          0 /],
	  'mSQL'    => [qw/ char(254)       char(255)        int       0          0 /],
      'MSSQL'   => [qw/ varchar(254)    varchar(255)     int       1          0 /],
      'Pg'      => [qw/ varchar(254)    varchar(255)     int       1          0 /],
      'PgPP'    => [qw/ varchar(254)    varchar(255)     int       1          0 /],
      'Sybase'  => [qw/ varbinary(254)  varbinary(255)   tinyint   1          0 /],
	  'Oracle'  => [qw/ varchar(254)    varchar(255)     integer   1          0 /],
	  'CSV'     => [qw/ varchar(254)    varchar(255)     integer   1          1 /],  # should never be used by SPAMBOX
	  'Informix'=> [qw/ nchar(254)      nchar(255)       integer   0          0 /],
	  'Solid'   => [qw/ varbinary(254)  varbinary(255)   integer   1          0 /],
	  'ODBC'    => [qw/ varbinary(254)  varbinary(255)   integer   1          0 /],
      'ADO'     => [qw/ varchar(254)    varchar(255)     int       1          0 /],
      'Firebird'=> [qw/ char(254)       char(255)        integer   1          0 /],
	  'DB2'     => ["varchar(254) not null","varchar(255)","integer",1,0],
	  );

  $Tie::RDBM::CAN_BIND{DB2} = 1;
  $Tie::RDBM::CAN_BIND{ADO} = 1;
  $Tie::RDBM::CAN_BIND{MSSQL} = 1;
  $Tie::RDBM::CAN_BIND{PgPP} = 1;
  $Tie::RDBM::CAN_BIND{Firebird} = 1;

  if (($DBusedDriver eq 'ODBC' || $DBusedDriver eq 'ADO') && $CanUseTieRDBM) {
       $DBhostTag = 'server';
       my $dbh = DBI->connect("DBI:$DBusedDriver:".($mydb ? "database=$mydb;" : '').($myhost ? "$DBhostTag=$myhost" : '' )."$DBOption", "$myuser", "$mypassword");
       $DBI::dbi_debug = $debug;
       if (!$dbh) {
         mlog(0,"Error: $DBI::errstr");
         mlog(0,"unable to get database information via $DBusedDriver!");
         mlog(0,"warning: database options will not be available!");
         $CanUseTieRDBM=0;
       } else {
         my $dbn = $dbh->get_info(17);
         my $dbv = $dbh->get_info(18);
         mlog(0,"info: found database: $dbn version: $dbv via $DBusedDriver");
         $dbn = 'mysql' if ($dbn =~ /mysql/io);
         $dbn = 'mSQL' if ($dbn =~ /mSQL/io);
         $dbn = 'Pg' if ($dbn =~ /Pg/io);
         $dbn = 'Sybase' if ($dbn =~ /Sybase/io);
         $dbn = 'Oracle' if ($dbn =~ /Oracle/io);
         $dbn = 'CSV' if ($dbn =~ /CSV/io);
         $dbn = 'Informix' if ($dbn =~ /Informix/io);
         $dbn = 'Solid' if ($dbn =~ /Solid/io);
         $dbn = 'DB2' if ($dbn =~ /DB2/io);
         $dbn = 'MSSQL' if ($dbn =~ /Microsoft SQL Server/io);
         $dbn = 'Firebird' if ($dbn =~ /Firebird/io);
#         if ($dbn =~ /Microsoft SQL Server/io) {$dbn = 'MSSQL'; $forceTrunc4ClearDB = 1;}
         if (exists $Tie::RDBM::Types{$dbn}) {
            $Tie::RDBM::Types{$DBusedDriver} = $Tie::RDBM::Types{$dbn};
            mlog(0,"info: using $dbn table structure for $DBusedDriver database $mydb");
         } else {
            mlog(0,"info: using default $DBusedDriver table structure for $DBusedDriver database $mydb");
         }
       }
       $dbh->disconnect() if ( $dbh );
       eval("no DBD::$DBusedDriver");
  }
  if ($DBusedDriver eq 'ADO' && ! defined *{'DBD::ADO::CLONE'}) {
      *{'DBD::ADO::CLONE'} = *{'main::ADO_Clone'};
  }
}
  print "\t\t\t\t\t[OK]\nloading caches and lists";

  &initFileHashes();      # init the file base hashes to share them with all threads

  eval('no BerkeleyDB;');

  $crashHMM = HMMreadCrashFiles();

  undef $SysLogObj;

  print "\t\t\t\t[OK]\nstarting maintenance worker thread -> init all databases\n";
  mlog(0,"starting maintenance worker thread [10000] - ThreadCycleTime is set to $MaintThreadCycleTime microseconds");
  $ComWorker{10000} = &share({});
  $ComWorker{10000}->{run} = 1;
  if ($ThreadStackSize) {
      $Threads{10000} = threads->create({'stack_size' => 1024*1024*$ThreadStackSize},\&ThreadMaintStart,10000);
  } else {
      $Threads{10000} = threads->create(\&ThreadMaintStart,10000);
  }
  my $watchtime = time;
  my %chars = ( 0 => '|', 1 => '/', 2 => '-', 3 => '\\' );
  my $ci = 0;
  my $lstep;
  while (! $ComWorker{10000}->{isstarted} && ! $ComWorker{10000}->{inerror}){
      $ci = 0 if $ci > 3;
      ThreadYield();
      Time::HiRes::sleep(0.1);
      my $step;
      if (time - $watchtime > 10 && ($step = $lastd{10000}) && $step ne $lstep) {
          $lstep = $step;
          $step =~ s/\r|\n/ /go;
          my $del = 71 - length($step);
          $del = 1 if $del < 1;
          print "\r10000: $step" . (' ' x $del);
      } else {
          print "\r$chars{$ci++}";
      }
  }
  print "\rstarting maintenance worker thread";
  print "\t\t\t".($ComWorker{10000}->{inerror}?'[FAILED]':'[OK]').(' ' x 100)."\nstarting $NumComWorkers communication worker threads ";

  mlog(0,"starting SMTP-worker-threads with ThreadCycleTime set to $ThreadCycleTime microseconds");
  mlog(0,"starting communication worker threads [1 to $NumComWorkers]");
  for (my $i = 1; $i <= $NumComWorkers; $i++) {
     newThread($i);
     print '.';
     while (! $ComWorker{$i}->{issleep} && ! $ComWorker{$i}->{inerror}){ThreadYield();}
  }
  print "\rstarting $NumComWorkers communication worker threads\t\t\t[OK]\nstarting rebuild SpamDB worker thread";

  mlog(0,"starting rebuild SpamDB worker thread [10001] - ThreadCycleTime is set to $RebuildThreadCycleTime microseconds");
  $ComWorker{10001} = &share({});
  $ComWorker{10001}->{run} = 1;
  if ($ThreadStackSize) {
      $Threads{10001} = threads->create({'stack_size' => 1024*1024*$ThreadStackSize},\&ThreadRebuildSpamDBStart,10001);
  } else {
      $Threads{10001} = threads->create(\&ThreadRebuildSpamDBStart,10001);
  }
  while (! $ComWorker{10001}->{isstarted} && ! $ComWorker{10001}->{inerror}){ThreadYield();}
  print "\t\t\t".($ComWorker{10001}->{inerror}?'[FAILED]':'[OK]')."\n";

  print "initializing main thread and logging\t\t\t[OK]\n";
  sleep 1;
  if ($CanUseBerkeleyDB) {
        eval('use BerkeleyDB;');
        if ($VerBerkeleyDB lt '0.42') {
            *{'BerkeleyDB::_tiedHash::CLEAR'} = *{'main::BDB_CLEAR'};
        }
        *{'BerkeleyDB::_tiedHash::STORE'} = *{'main::BDB_STORE'};
        *{'BerkeleyDB::_tiedHash::DELETE'} = *{'main::BDB_DELETE'};
  }

  if ($CanUseSPAMBOX_WordStem) {
      $Lingua::Stem::Snowball::stemmifier = Lingua::Stem::Snowball::Stemmifier->new unless ref($Lingua::Stem::Snowball::stemmifier);
  }
  
  &openLogs();
  
  if (! $silent) {
      binmode STDOUT;
      binmode STDERR;
  }

  &mlogWrite();
  
  &WaitForAllThreads;
  
  $canNotify = 1;
  
  if ($CanUseThreadState && $WorkerCPUPriority) {
      for (my $i = 1; $i <= $NumComWorkers; $i++) {
         my $po = $Threads{$i}->priority($WorkerCPUPriority);
         my $pn = $Threads{$i}->priority;
         $po = 0 if (! $po);
         $pn = 0 if (! $pn);
         mlog(0,"info: CPU priority changed for Worker_$i from $po to $pn") if ($po != $pn);
      }
  }
  if ($CanUseThreadState) {                   # set down thread priority for MaintThread and RebuildThread
     my $po = $Threads{10000}->priority(2);
     my $pn = $Threads{10000}->priority;
     $po = 0 if (! $po);
     $pn = 0 if (! $pn);
     mlog(0,"info: CPU priority changed for Worker_10000 from $po to $pn") if ($po != $pn);
     $po = $Threads{10001}->priority(2);
     $pn = $Threads{10001}->priority;
     $po = 0 if (! $po);
     $pn = 0 if (! $pn);
     mlog(0,"info: CPU priority changed for Worker_10001 from $po to $pn") if ($po != $pn);
  }
  &mlogWrite();
  mlog(0,"try using $DBusedDriver database \<$mydb\> for selected tables") if $DBisUsed;
  &mlogWrite();
  &initPrivatHashes('clean');
  &mlogWrite();
  %SMTPSessionIP = ();
  &ResetStats();
  &mlogWrite();
  &initDBHashes();        # init DB based hashes - they are not shared
  &mlogWrite();
  &initFileHashes('AdminGroup');  # AdminGroup is never shared;
  &mlogWrite();

  ConfigChangePassword('webAdminPassword', '', '', 0) if $usedCrypt == -1; # change the encryption engine now !
  
# check if there are at least 500 records in spamdb (~10KB)
  mlog(0,"start analyze spamdb") if $MaintenanceLog >= 2;
  my $i = $haveSpamdb = getDBCount('Spamdb','spamdb');
  $currentDBVersion{'Spamdb'} = $Spamdb{'***DB-VERSION***'} || 'n/a';
  mlog(0,'spamdb has '.nN($i).' records') if $MaintenanceLog >= 2;
  mlog(0,"warning: Bayesian spam database has only $i records") if ($i < 500 && $spamdb);
  mlog(0,"warning: the current Spamdb is possibly incompatible to this version of SPAMBOX. Please run a rebuildspamdb. current: $currentDBVersion{Spamdb} - required: $requiredDBVersion{Spamdb}") if ($haveSpamdb && $currentDBVersion{Spamdb} ne $requiredDBVersion{Spamdb});
  &mlogWrite();
  
# check if there are at least 50 records in whitelist (~1KB)
  mlog(0,"start analyze whitelist") if $MaintenanceLog >= 2;
  $i = getDBCount('Whitelist','whitelistdb');
  mlog(0,'whitelist has '.nN($i).' records') if $MaintenanceLog >= 2;
  mlog(0,"warning: whitelist has only $i records: (ignore if this is a new install)") if ($i < 50 );

  if ($DoHMM) {
      $haveHMM = getDBCount('HMMdb','spamdb');
      mlog(0,"The Hidden-Markov-Model-DB is empty - the HMM check is disabled") if $MaintenanceLog && ! $haveHMM;
      mlog(0,'The Hidden-Markov-Model-DB has '.nN($haveHMM).' records.') if $MaintenanceLog >= 2 && $haveHMM;
  }
  $currentDBVersion{'HMMdb'} = $HMMdb{'***DB-VERSION***'} || 'n/a';
  mlog(0,"warning: the current HMMdb is possibly incompatible to this version of SPAMBOX. Please run a rebuildspamdb. current: $currentDBVersion{HMMdb} - required: $requiredDBVersion{HMMdb}") if ($DoHMM && $haveHMM && $currentDBVersion{HMMdb} ne $requiredDBVersion{HMMdb});

  if ($mysqlSlaveMode) {
      mlog(0,"assp is running in mysqlSlaveMode - no maintenance will be done for database tables!");
  }
  &mlogWrite();

  if ($SNMP && $CanUseNetSNMPagent) {
      ConfigChangeSNMP('SNMPAgentXSocket','',$Config{SNMPAgentXSocket},'Initializing');
  } else {
      ConfigStats();
  }
  &mlogWrite();
  $shuttingDown=$doShutdown=0;
  $smtpConcurrentSessions=0;
  threads->yield;
  $Stats{starttime}=time;
  $Stats{version}="$version$modversion";

  my ($lsn,$lsnI) = newListen($listenPort,\&ConToThread,1);
  @lsn = @$lsn; @lsnI = @$lsnI;
  for (@$lsnI) {s/:::/\[::\]:/o;}
  mlog(0,"listening for SMTP connections on ".join(' , ',@$lsnI)) if @lsn;
  &mlogWrite();

  if ($CanUseIOSocketSSL && $listenPortSSL) {
      my ($lsnSSL,$lsnSSLI) = newListenSSL($listenPortSSL,\&ConToThread,1);
      @lsnSSL = @$lsnSSL; @lsnSSLI = @$lsnSSLI;
      for (@$lsnSSLI) {s/:::/\[::\]:/o;}
      mlog(0,"listening for SMTPS (SSL) connections on ".join(' , ',@$lsnSSLI)) if @lsnSSL;
      &mlogWrite();
  }

  my @dummy;
  if ($CanUseIOSocketSSL && $enableWebAdminSSL) {
      my ($WebSocket,$dummy)  = newListenSSL($webAdminPort,\&NewWebConnection);
      @WebSocket = @$WebSocket;
      for (@$dummy) {s/:::/\[::\]:/o;}
      mlog(0,"listening for admin HTTPS connections on ".join(' , ',@$dummy)) if @WebSocket;
  } else {
      my ($WebSocket,$dummy)  = newListen($webAdminPort,\&NewWebConnection);
      @WebSocket = @$WebSocket;
      for (@$dummy) {s/:::/\[::\]:/o;}
      mlog(0,"listening for admin HTTP connections on ".join(' , ',@$dummy)) if @WebSocket;
  }
  &mlogWrite();

  if ($CanUseIOSocketSSL && $enableWebStatSSL) {
      my ($StatSocket,$dummy) = newListenSSL($webStatPort,\&NewStatConnection);
      @StatSocket = @$StatSocket;
      for (@$dummy) {s/:::/\[::\]:/o;}
      mlog(0,"listening for stat HTTPS connections on ".join(' , ',@$dummy)) if @StatSocket;
  } else {
      my ($StatSocket,$dummy) = newListen($webStatPort,\&NewStatConnection);
      @StatSocket = @$StatSocket;
      for (@$dummy) {s/:::/\[::\]:/o;}
      mlog(0,"listening for stat HTTP connections on ".join(' , ',@$dummy)) if @StatSocket;
  }
  &mlogWrite();

  if($listenPort2) {
    my ($lsn2,$lsn2I) = newListen($listenPort2,\&ConToThread,1);
    @lsn2 = @$lsn2; @lsn2I = @$lsn2I;
    for (@$lsn2I) {s/:::/\[::\]:/o;}
    mlog(0,"listening for additional SMTP connections on ".join(' , ',@$lsn2I)) if @lsn2;
    &mlogWrite();
  }

  if($relayHost && $relayPort) {
    my ($lsnRelay,$lsnRelayI)=newListen($relayPort,\&ConToThread,1);
    @lsnRelay = @$lsnRelay; @lsnRelayI = @$lsnRelayI;
    for (@$lsnRelayI) {s/:::/\[::\]:/o;}
    mlog(0,"listening for SMTP relay connections on ".join(' , ',@$lsnRelayI)) if @lsnRelay;
    &mlogWrite();
  }

  &mlogWrite();
  while ((my $k,my $v) = each(%Proxy)) {
       my ($to,$allow) = split(/<=/o, $v);
       $allow = " allowed for $allow" if ($allow);
       my ($ProxySocket,$dummy) = newListen($k,\&ConToThread,2);
       $ProxySocket{$k} = shift @$ProxySocket;
       if ($ProxySocket{$k}) {
           for (@$dummy) {s/:::/\[::\]:/o;}
           mlog(0,"proxy started: listening on @$dummy forwarded to $to$allow");
           &mlogWrite();
       }
  }
  my $isproxy = scalar(keys %ProxySocket) ? ' and Proxy':'';
  mlog(0,"warning : DisableSMTPNetworking is switch on - SMTP$isproxy listeners will be switched off") if ($DisableSMTPNetworking);

  mlog(0,"current PID: $$");

  &mlogWrite();

  if ($StartError) {
      mlog(0,"*******************************************************************************************");
      mlog(0,"error: an unrecoverable startup error was detected - please look in to previous messages");
      mlog(0,"error: SPAMBOX will not accept any SMTP connection - 'DisableSMTPNetworking' is set to on");
      mlog(0,"error: solve the problem and restart SPAMBOX");
      mlog(0,"error: after restart - login in to GUI and change 'DisableSMTPNetworking' to off, if needed");
      mlog(0,"*******************************************************************************************");
      configUpdateSMTPNet('DisableSMTPNetworking','0','2','');
      &mlogWrite();
  }
  $cmdQueueReleased = 1;
  mlog(0,"info: command queue released");
  $allowPOP3 = 1;
  mlog(0,"info: POP3 collection is now allowed")
     if ($POP3Interval && -e "$base/spambox_pop3.pl" && $POP3ConfigFile =~ /^ *file: *(?:.+)/io);
  &mlogWrite();
  if($pidfile) {open($PIDH,'>',"$base/$pidfile"); $PIDH->autoflush; print $PIDH $$;}
  nixUsers();
  &mlogWrite();
  activeRemoteSupport();
  &mlogWrite();
}
