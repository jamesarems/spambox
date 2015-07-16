#line 1 "sub main::genCerts"
package main; sub genCerts {
# Very basic script to create SSL/TLS certificates for ASSP

use File::Temp qw/ tempfile tempdir /;
my $template;

my $SERVER_key = "$base/certs/server-key.pem";
my $SERVER_key_pub = "$base/certs/server-key-pub.pem";
my $SERVER_csr = "$base/certs/server-csr.pem";
my $SERVER_crt = "$base/certs/server-cert.pem";

return if (-e "$base/certs/server-key.pem" and -e "$base/certs/server-cert.pem");

my %opts = (
    C  => 'XY',
    ST => 'unknown',
    L  => 'unknown',
    O  => 'ASSP',
    OU => 'Server',
    CN => $myName,
    emailAddress => $EmailAdminReportsTo,
);

my @C = split(/\|/o, $MyCountryCodeRe);
my $C = shift(@C);
$C = $1 if (! $C && $localhostname =~ /\.(\S)$/o);
$C = $1 if (! $C && $myName =~ /\.(\S)$/o);
$opts{C} = $C ? $C : $opts{C};
$opts{CN} = $opts{CN} ? $opts{CN} : $localhostname;
$opts{emailAddress} = $opts{emailAddress} ? $opts{emailAddress} : "postmaster\@$opts{CN}";

my $msg = "info: used parms for certs:" ;
foreach (keys %opts) {
    $msg .= " $_ - $opts{$_},";
}
chop $msg;
mlog(0,$msg);

mkdir("$base/certs") unless -d "$base/certs";

my $CA_key = "$base/certs/server-ca.key";
my $CA_crt = "$base/certs/server-ca.crt";
my $CA_serial = "$base/certs/.server-cert.serial";

my ($CA, $CAfilename) = tempfile( $template, DIR => "$base/certs", UNLINK => 1);

print ${CA} return_cfg('CA',%opts);
close ${CA};

system('openssl', 'genrsa', '-out', $CA_key, 2048) == 0
    or (mlog(0, "error: Cannot create CA key: $?") and return);

system('openssl', 'req', '-config', $CAfilename, '-new', '-x509',
	'-days', (365*20), '-key', $CA_key,
	'-out', $CA_crt) == 0
    or (mlog(0, "error: Cannot create CA cert: $?") and return);


my ($SERVER, $SERVERfilename) = tempfile( $template, DIR => "$base/certs", UNLINK => 1);
print ${SERVER} return_cfg($opts{OU},%opts);
close ${SERVER};

system('openssl', 'genrsa', '-out', $SERVER_key, 1024) == 0
    or (mlog(0, "error: Cannot create server key: $?") and return);

system('openssl', 'req', '-config', $SERVERfilename, '-new',
	'-key', $SERVER_key, '-out', $SERVER_csr) == 0
    or (mlog(0, "error: Cannot create server cert: $?") and return);

my ($SIGN, $SIGNfilename) = tempfile( $template, DIR => "$base/certs", UNLINK => 1);
print ${SIGN} <<"EOT";
extensions = x509v3
[ x509v3 ]
subjectAltName   = email:copy
nsComment        = ssl and tls certificate
nsCertType       = server
EOT
close ${SIGN};

open my $SERIAL, '>', $CA_serial;
print ${SERIAL} "01\n";
close ${SERIAL};

system('openssl', 'x509', '-extfile', $SIGNfilename, '-days', (365*20),
	'-CAserial', $CA_serial, '-CA', $CA_crt,
	'-CAkey', $CA_key, '-in', $SERVER_csr,
	'-req', '-out', $SERVER_crt) == 0
    or (mlog(0, "error: Cannot sign cert: $?") and return);

system('openssl', 'rsa', '-in', $SERVER_key, '-out', $SERVER_key_pub,
       '-pubout', '-outform', 'PEM') == 0
    or (mlog(0, "error: Cannot create public key: $?") and return);

mlog(0,"info: successfuly created certificates in $base/certs");

my $dkimfile = "$base/certs/dkim-pub.txt";
my $df;
my $kf;
my $dfout = "\"k=rsa; t=y; p=";
open $kf , '<',"$SERVER_key_pub";
open $df , '>',"$dkimfile";
binmode $df;
while (<$kf>) {
    s/\r|\n//go;
    next if /---/o;
    $dfout .= $_;
}
$dfout .= "\"";
print $df $dfout;
close $df;
close $kf;
mlog(0,"info: successfuly created DKIM public key NS TXT string in $dkimfile");
}
