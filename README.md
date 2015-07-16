# SpambOx
Opensource Anti spam server.
Forked from ASSP server.

We need more eye catching web gui.
Under development.

#Installation

Require perl-5.1x

Recommented OS : CentOS-7

Required Packages : 
gcc openssl-devel perl-Net-SMTPS perl-IO-Compress-Zlib perl-Text-Glob perl-Number-Compare perl-Convert-TNEF perl-Digest-SHA1 perl-Email-MIME perl-Email-Send perl-Email-Valid perl-File-ReadBackwards perl-MIME-Types perl-Mail-DKIM perl-Mail-SPF perl-Net-CIDR-Lite perl-Net-DNS perl-Net-IP-Match-Regexp perl-Net-SMTP-SSL perl-Time-HiRes perl-Crypt-CBC perl-IO-Socket-SSL perl-Sys-MemInfo perl-Time-HiRes perl-Tie-DBI perl-LWP-Authen-Negotiate clamd perl-Net-IP perl-Text-Unidecode perl-Schedule-Cron-Events perl-BerkeleyDB perl-LDAP perl-CPAN perl-local-lib perl-CPAN-Meta-Requirements unzip deltarpm net-tools policycoreutils-python

CPAN Packages :  cpan -i Unicode::GCString Sys::CpuAffinity Thread::State Thread::Queue Schedule::Cron File::Scan::ClamAV Sys::Syslog IO::Socket::INET6 Lingua::Stem::Snowball Lingua::Identify Archive::Extract Archive::Zip Archive::Tar Mail::SRS Net::SenderBase Tie::DBI Crypt::OpenSSL::AES Regexp::Optimizer Schedule::Cron::Events Mail::SPF::Query File::Scan::ClamAV IO::Socket::SSL Mail::SPF::Query File::Scan::ClamAV

Clone Spambox Packages :  git clone git@github.com:jamesarems/spambox.git   or  download zip file. 

cd spambox

chmod +x install-box.sh

Follow instructions.

# Web acces 

https://server-ip:8090

# Default Credentials

username : root

password : spambox
