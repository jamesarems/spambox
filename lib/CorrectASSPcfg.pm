package CorrectASSPcfg;
use strict qw(vars subs);

# V2 build 15135 (at least !)
#
# If this Package is available, it will be loaded by assp and the sub set will be called, 
# after the configuration is parsed.
# You are free to modify any config parameter here - see the examples in 'sub set'.

# *********************************************************************************************************************************************
# hidden config variables that could be changed using this module CorrectASSPcfg.pm
# or that could be changed using a commandline switch like --enableCrashAnalyzer:=1
# the values shown are the default values
# *********************************************************************************************************************************************

# CrashAnalyzer related
# $main::enableCrashAnalyzer = 0;            # (0/1) enable the automatic crash analyzer (CA)
# $main::CrashAnalyzerTopCount = 10;         # (number > 0) number of records used for the CA top count
# $main::CrashAnalyzerWouldBlock = 1;        # (0/1) block the mail if CA detects that the mail would crash ASSP

# IP related
# $main::IPv6TestPort = '51965';             # (port number) the port number that is used at startup to bind IPv6 to - to check if IPv6 is available
# $main::forceDNSv4 = 1;                     # (0/1) force DNS queries to use IPv4 instead to try IPv6 first
# $main::DNSresolverLifeTime = 3600;         # the max lifetime of a DNS-Resolver object and it's sockets in seconds

# Bayesian and HMM related
# $main::HMMSequenceLength = 4;              # (number > 0) count of words used for a sequence
# $main::HMMDBWords = 600;                   # (number > 0) number of words used per mail in rebuildspamdb
# $main::BayesDomainPrior = 2;               # (number > 0) Bayesian/HMM domain entry priority (1 = lowest)
# $main::BayesPrivatPrior = 3;               # (number > 0) Bayesian/HMM private/user entry priority (1 = lowest)
# $main::debugWordEncoding = 0;              # (0/1) write/debug suspect word encodings to debug/_enc_susp.txt

# logging related
# $main::AUTHLogUser = 0;                    # (0/1) write the username for AUTH (PLAIN/LOGIN) to maillog.txt
# $main::AUTHLogPWD = 0;                     # (0/1) write the userpassword for AUTH (PLAIN) to maillog.txt
# $main::Unidecode2Console = 0;              # (0/1) use Text::Unidecode to decode NONASCII characters to ASCII - if available  - if set - 'ConsoleCharset' is ignored
# $main::showMEM = 0;                        # (0/1) show the current memory usage in every worker
# $main::AnalyzeLogRegex = 0;                # (0/1) enables enhanced regex analyzing (in console mode only)

# database related
# $main::forceTrunc4ClearDB = 0;             # (0/1) try/force a 'TRUNCATE TABLE' instead of a 'DELETE FROM' - 'DELETE FROM' is used as fall back if the truncate fails
# $main::DoSQL_LIKE = 1;                     # (0/1) do a 'DELETE FROM table WHERE pkey LIKE ?' to remove generic keys
# $main::lockBDB = 0;                        # (0/1) use the CDB locking for BerkeleyDB (default = 0)
# $main::lockDatabases = 0;                  # (0/1) locks all databases on access in every worker to prevent access violation
# $main::DBCacheSize = 12;                   # (number > 0) database cache record count , if less it will be set to NumComWorkers * 2 + 8

# some more
# $main::SPF_max_dns_interactive_terms = 15; # (number > 0) max_dns_interactive_terms max number of SPF-mechanism per domain (defaults to 10)
# $main::neverQueueSize = 12000000;          # (number > 0) never queue mails larger than these number of bytes
# $main::SpamCountNormCorrection = 0;        # (+/- number in percent) correct the required by X% higher
# $main::FileScanCMDbuild_API;               # called if defined in FileScanOK with - $FileScanCMDbuild_API->(\$cmd,$this) - $cmd in place modification
# $main::WebTrafficTimeout = 60;             # Transmission timeout in seconds for WebGUI and STATS connections
# $main::DisableSyslogKeepAlive = 0;         # disable sending the keep alive '***assp&is%alive$$$' to the Syslog-Server
# $main::noRelayNotSpamTag = 1;              # (0/1) do per default the NOTSPAMTAG for outgoing mails

# $main::WorkerScanConLimit = 1;             # (number >= 0) connection count limit in SMTP threads before move the file scan to high threads

# $main::fakeAUTHsuccess = 0;                # (0/1/2) fake a 235 reply for AUTH success - move the connection to NULL - collect the mail in spam - used for honeypots - 2=with damping
# $main::fakeAUTHsuccessSendFake = 0;        # (0/1) send the faked mails from the honeypot - make the spammers believe of success - attention: moves assp in to something like an open relay for these mails

# $main::protectASSP = 1;                    # (0/1) rmtree will only remove files and folders in base/t[e]mp...

# $main::enableBRtoggleButton = 1;           # (0/1) show the "toggle view" button in HTML BlockReports
# *********************************************************************************************************************************************

sub set {
    mlog(0,"info: sub 'set' in module CorrectASSPcfg.pm is called");

#    $main::enableBRtoggleButton = 0;
#    mlog(0,"info: the 'toggle view' button in BlockReports is not shown");

#    $main::enableCrashAnalyzer = 1;
#    mlog(0,"info: enableCrashAnalyzer set to 1");

#    $main::showMEM = 1;
#    mlog(0,"info: assp shows the current memory usage in every worker");
}

# use this sub to change the FilsScanCMD to your needs - modify ${$cmd} in place # uncomed the lines
#sub setFSCMD {
#    my ($cmd, $this) = @_;
#    my @rcpt = split(/ /o,$this->{rcpt});
#    my $sender = $this->{mailfrom};
#    my $ip = $this->{ip};
#    my $cip = $this->{cip};
#    
#    ${$cmd} = '';
#}

sub mlog {
    &main::mlog(@_);
} 

=head1 example

# example for client certificate GUI-logins - remove the 'head1' (above) and the 'cut' (below) lines 
# to enable the code
#
# read the SSL/TLS section in the GUI


# for example define the known good certificates
our %validCerts = (
    '/description=.../C=../ST=.../L=.../CN=.../emailAddress=.....' => {valid => 1, login => 'the_assp_admin_user'},
    '/serialNumber=..../CN=....'  => {valid => 1, login => 'root'},

    '/C=IL/O=StartCom Ltd./OU=Secure Digital Certificate Signing/CN=StartCom Class 1 Primary Intermediate Client CA' => {valid => 1},
    '/C=IL/O=StartCom Ltd./OU=Secure Digital Certificate Signing/CN=StartCom Class 2 Primary Intermediate Client CA' => {valid => 1},
    '/C=DE/O=Elster/OU=CA/CN=ElsterIdNrSoftCA' => {valid => 1},
);


sub checkWebSSLCert {
    my ($OpenSSLSays,$CertStackPtr,$DN,$OpenSSLError, $Cert)=@_;
#    mlog(0,"info: checkWebSSLCert called");
    my $subject = my $s = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($Cert));
    $s =~ s/^\///o;
    my %cert = split(/\/|=/o,$s);
#    mlog(0,"cert: '$subject'")
    if ($validCerts{$subject}{valid}) {
        mlog(0,"info: ($OpenSSLSays) person '$cert{CN}' located in '$cert{C}/$cert{ST}/$cert{L}', email address '$cert{emailAddress}', logged in as 'root'")  if $validCerts{$subject}{login};
        mlog(0,"info: ($OpenSSLSays) person '$cert{CN}' located in '$cert{C}/$cert{ST}/$cert{L}', email address '$cert{emailAddress}'") if $cert{emailAddress} && ! $validCerts{$subject}{login};
        @main::ExtWebAuth = ($validCerts{$subject}{login}) if $validCerts{$subject}{login};
        return 1;
    } elsif ($OpenSSLSays) {
        mlog(0,"warning: unknown valid certificate: $subject");
    } else {
        mlog(0,"error: unknown invalid certificate: openssl-error: '$OpenSSLError' - '$subject'");
    }
    return $OpenSSLSays;
}

sub configWebSSL {
    my $parms = shift;
    mlog(0,"info: SSLWEBConfigure called");
    return;
}

=cut
 
1;

