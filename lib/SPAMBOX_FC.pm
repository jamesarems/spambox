#!/usr/bin/perl --
# SPAMBOX V2 file commander
#
# copyright Thomas Eckardt (2013/2014)
#####################################

package SPAMBOX_FC;

use strict qw(vars subs);
use Archive::Extract();
use Archive::Zip();
use Archive::Tar;
use IO::Compress::Gzip();
use IO::Compress::Bzip2();
use Email::MIME();

our $TEST = 0;

our $VERSION = '1.05';
our $requ_build = 13264;
our $base;
our $ActWebSess;
our $out;
our %CanFile;
our ($head,$qs);
our $freespace_kbl = 0;
our $totalspace_kbl = 0;
our $freespace_kbr = 0;
our $totalspace_kbr = 0;
our ($voll,$volr) = ('[_drive_]','[_drive_]');

our $totalsizel = 0;
our $totalfilesl = 0;
our $totaldirsl = 0;
our $totalsizer = 0;
our $totalfilesr = 0;
our $totaldirsr = 0;

sub checkENV {
    my ($file,$version) = @_;
    my $error;
    my $base = $main::base;
    my ($OK,$ver);
    open(my $F, '<', "$base/$file") or return "unable to find required file $base/$file - $!\n";
    while (<$F>) {
        $ver = $1 if /VERSION\s+(\d+\.\d+)/o;
        last if $ver;
    }
    close($F);
    if (! $ver) {
        $error .= "file $base/$file has no version\n";
    } elsif($ver < $version) {
        $error .= "file $base/$file has version $ver - required is version $version\n";
    }
    return $error;
}

BEGIN {
    my $error;
    $error = "SPAMBOX file commander version $VERSION requires at least SPAMBOX V2 build $requ_build\n" if $requ_build > $main::build || $main::version !~ /^2\./o;
    my %files = (
         'images/fc.js' => 1.03,
         'images/fc.css' => 1.03
    );
    foreach (keys(%files)) {
        $error .= checkENV($_,$files{$_});
    }
    die $error if ! $^C && $error;
}

sub mlog {
    &main::mlog(@_);
}

sub fcHist {
    my $msg = shift;
    $msg =~ s/^[\s\r\n]+//o;
    $msg =~ s/[\s\r\n]+$//o;
    return unless $msg;
    my $t = &main::timestring();
    my $u = $main::WebIP{$ActWebSess}->{user};
    open(my $F, '>>', "$base/notes/fc-history.txt") or return;
    binmode $F;
    print $F "$t $u - $msg\n";
    close $F;
    return;
}

sub canDoFile {
    my $file = shift;
    my $user = $main::WebIP{$ActWebSess}->{user};
    return 1 if ($user eq 'root');          # root is OK
    return 0 if $file =~ /\.(?:js|pl(?:\.run)?|pm|cfg(?:\.bak)*)$/oi;   # no scripts and configs
    return 0 if $file =~ /^\Q$base\E\/certs(?:\/|$)/oi;                 # no certificates
    return 1 if $file =~ /\/$/o;                                        # folders are OK
    if ($file =~ /^\Q$base\E\/([^\/]+)\//o) {                           # file in a subdir
        my $dir = $1;
        return 1 if ($dir !~ /^files$/o);                               # if not in files - subdir OK
    }
    if (! scalar(keys(%{$CanFile{$user}}))) {
        foreach (keys(%main::CryptFile)) {                              # no crypt files
            $CanFile{$user}{$_} = 1;
        }
        foreach my $k (keys(%main::FileUpdate)) {                       # user to cfg file check
            my ($name) = $k =~ /^\Q$file\E(.+)$/;
            next unless $name;
            next unless exists $main::Config{$name};
            my $can = &main::canUserDo($user,'cfg',$name);
            if (! $can) {
                 $CanFile{$user}{$file} = 1;
                if (exists $main::FileIncUpdate{$k}) {                  # check include files
                    foreach (keys(%{$main::FileIncUpdate{$k}})) {
                         $CanFile{$user}{$_} = 1;
                    }
                }
            }
        }
        foreach my $dbGroup (@main::GroupList) {
            foreach my $dbGroupEntry (@{'main::'.$dbGroup}) {
                my ($KeyName,$dbConfig,$CacheObject,$realFileName,$mysqlFileName,$FailoverValue,$mysqlTable) = split(/,/o,$dbGroupEntry);
                if ((! $main::CanUseTieRDBM && ! $main::CanUseBerkeleyDB) || ${'main::'.$dbConfig} !~ /DB:/o || $main::failedTable{$KeyName} == 1) {
                    if ($dbGroup eq 'AdminGroup') {
                         $CanFile{$user}{"$base/$realFileName"} = 1;
                        next;
                    }
                     $CanFile{$user}{"$base/$realFileName"} = 1 unless &main::canUserDo( $user, 'cfg', $dbConfig);
                }
            }
        }
        $CanFile{$user}{'LASTTIME'} = time;
    }
    return 1 unless exists  $CanFile{$user}{$file};
    return !  $CanFile{$user}{$file};
}

sub getDriveInfo {
    my ($dir,$p) = @_;
    if ($^O eq 'MSWin32') {
        eval('use Win32::DriveInfo();1;') or do {
            mlog(0,"warning: SPAMBOX_FC is missing module 'Win32::DriveInfo' - $@");
            return;
        };
        my $drive = substr($dir,0,1);
        my ( $SectorsPerCluster,
             $BytesPerSector,
             $NumberOfFreeClusters,
             $TotalNumberOfClusters,
             $FreeBytesAvailableToCaller,
             $TotalNumberOfBytes,
             $TotalNumberOfFreeBytes) = eval{Win32::DriveInfo::DriveSpace($drive);};
             ${"freespace_kb$p"} = commify(int($TotalNumberOfFreeBytes/1024));
             ${"totalspace_kb$p"} = commify(int($TotalNumberOfBytes/1024));
        my ( $VolumeName,
             $VolumeSerialNumber,
             $MaximumComponentLength,
             $FileSystemName, @attr) = Win32::DriveInfo::VolumeInfo($drive);
             ${"vol$p"} = $VolumeName ? "[$VolumeName]" : '[_none_]';
    } else {
        eval('use Filesys::Df();1;') or do {
            mlog(0,"warning: SPAMBOX_FC is missing module 'Filesys::Df' - $@");
            return;
        };
        my $ref = eval{Filesys::Df::df($dir)};
        ${"freespace_kb$p"} = commify($ref->{bavail});
        ${"totalspace_kb$p"} = commify($ref->{blocks});
        ${"vol$p"} = "[nix]";
    }
}

sub fileList {
    my @d;
    my @g;
    for (@_) {
        if (-d $_) {
            push @g , fileList(&main::Glob($_ . '/*'));
        } else {
            push @g, $_ if canDoFile($_);
        }
    }
    return @g;
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1./go;
    return scalar reverse $text;
}

sub file_name {
    my $filename = shift;

    $filename =~ s/^(.+)\.[^.]+$/$1/o;
    return $filename;
}

sub file_extension {
    my $filename = shift;

    return $filename if $filename =~ s/^.+\.([^.]+)$/$1/o;
    return '';
}

sub full_file_name {
    my $filename = shift;

    return lc($filename);
}

sub formNumDataSize {
    my $size = shift;
    $size ||= 0;
    my $res;
    if ($size >= 1099511627776) {
        $res = sprintf("%.2fT", $size / 1099511627776);
    } elsif ($size >= 1073741824) {
        $res = sprintf("%.2fG", $size / 1073741824);
    } elsif ($size >= 1048576) {
        $res = sprintf("%.2fM", $size / 1048576);
    } elsif ($size >= 1024) {
        $res = sprintf("%.2fk", $size / 1024);
    } else {
        $res = $size . 'B';
    }
    return $res;
}

sub fillSide {
my ($side,$adr,$sort,$filter,$rlink) = @_;

my $sd;
$sd = $1 if $sort =~ s/([ud])$//o;
$sd ||= 'u';
my $nsd = $sd eq 'u' ? 'd' : 'u';

my $sorts = $side eq 'left' ? 'sortl' : 'sortr';
my $adrs  = $side eq 'left' ? 'adrl' : 'adrr';
my $p     = $side eq 'left' ? 'l' : 'r';

while (! $main::dF->("$adr")) {
    last unless $adr =~ s/^(\Q$base\E.*?)\/[^\/]+$/$1/o;
}

my %ar = (
   'u' => '&#10548;',
   'd' => '&#10549;'
);

my %arrow = (
    'name' => '',
    'ext'  => '',
    'size' => '',
    'date' => ''
);
my %sl = (
    'name' => '',
    'ext'  => '',
    'size' => '',
    'date' => ''
);

$arrow{$sort} = $ar{$sd};
$sl{$sort} = $nsd;

my $fltre = $filter;
$fltre =~ s/\./\\./go;
$fltre =~ s/\*/.*/go;
$fltre =~ s/\?/./go;

my $hadr = $adr;
$hadr = '['.$main::WebIP{$ActWebSess}->{"fc_zip_$p"}[0].']' if exists $main::WebIP{$ActWebSess}->{"fc_zip_$p"};

my $outlist = '<div id="'.$side.'menu">';
$outlist .= <<EOT;
<div id="$p-list" class="list-disk">
<p>$hadr&nbsp;&nbsp;<b>($filter)</b></p>
</div>
<table name="table_$p" class="resizable thead"/>
 <colgroup>
  <col class="name" />
  <col class="ext"  name="ext$p" />
  <col class="size" name="size$p" />
  <col class="date" name="date$p" />
 </colgroup>
 <thead>
  <tr>
   <th scope="col"><a href="?$rlink$adrs=$adr&amp;$sorts=name$sl{name}&amp;filter$p=$filter">$arrow{name} Name</a></th>
   <th scope="col" name="ext$p"><a href="?$rlink$adrs=$adr&amp;$sorts=ext$sl{ext}&amp;filter$p=$filter" >$arrow{ext} Ext</a></th>
   <th scope="col" name="size$p"><a href="?$rlink$adrs=$adr&amp;$sorts=size$sl{size}&amp;filter$p=$filter">$arrow{size} Size</a></th>
   <th scope="col" name="date$p"><a href="?$rlink$adrs=$adr&amp;$sorts=date$sl{date}&amp;filter$p=$filter">$arrow{date} Date</a></th>
  </tr>
 </thead>
</table>
<div class="list-table" onmouseover="document.getElementById('$p-list').style.backgroundColor='#000080';" onmouseout="document.getElementById('$p-list').style.backgroundColor='#808080';">
<table name="table_$p" class="resizable tbody"/>
<tbody>
EOT

my %all = (
    'dirs'    =>   [],
    'files'   =>   []
);

my $sorting =  ($sort eq 'name') ? \&full_file_name
              :($sort eq 'ext' ) ? \&file_extension
              :($sort eq 'size') ? \&main::fsize
              :($sort eq 'date') ? \&main::ftime
              :\&full_file_name ;

my ($s1,$s2) = ('a','b');
($s1,$s2) = ('b','a') if $sd eq 'd';

my @dirArray;
if ($sorting) {
    @dirArray =  map { $_->[0] }
                 sort { ${$s1}->[1] <=> ${$s2}->[1] || lc(${$s1}->[1]) cmp lc(${$s2}->[1])}
                 map { [ $_, $sorting->("$adr/$_") ] } $main::unicodeDH->($adr);
} else {
    @dirArray = $main::unicodeDH->($adr);
}

foreach (@dirArray) {
    if ($main::dF->("$adr/$_"))
    {
        push(@{$all{dirs}}, $_);
    }
    else
    {
        push(@{$all{files}}, $_);
    }
}

my $id = 0;
foreach my $dir (@{$all{dirs}}) {
    if ($dir ne "." && $dir =~ /^$fltre$/ && canDoFile("$adr/$dir/"))
    {
        if ($dir eq '..' && $adr eq $base) {
            $out =~ s/$p\_switch\.\.to\.\.updir_$p/?$rlink$adrs=$base&amp;$sorts=$sort$sd&amp;filter$p=$filter/;
            next;
        }
        my $adr = $adr;
        my $ldir = '/'.$dir;
        $id++;
        my $rid = "id=\"rowd$p$id\"";
        if ($dir eq '..') {
            $ldir = '';
            $rid = '';
            $id--;
            $adr =~ s/\/[^\/]+\/?$//o;
            $adr = $base if $adr !~ /^\Q$base\E/o;
            $out =~ s/$p\_switch\.\.to\.\.updir_$p/?$rlink$adrs=$adr$ldir&amp;$sorts=$sort$sd&amp;filter$p=$filter/;
        }
        $outlist .= "<tr $rid name=\"$adr$ldir\" class=\"trow\" ondblclick=\"window.location.href='?$rlink$adrs=$adr$ldir&amp;$sorts=$sort$sd&amp;filter$p=$filter'; WaitDiv();\" onclick=\"toggleItem$side(this,'$adr$ldir','trow','dir',1);\">";
        $outlist .= "<td class=\"dir m\">";
        $outlist .= $dir;
        ${"totaldirs$p"}++ if $dir ne '..';
        $outlist .= "</td>";
        $outlist .= "<td name=\"ext$p\"></td>";    # no ext here
        $outlist .= "<td name=\"size$p\">&#60;DIR&#62;</td>";
        $outlist .= "<td name=\"date$p\">".&main::timestring(&main::ftime($dir),'','DD.MM.YYYY hh:mm:ss')."</td>";
        $outlist .= "</tr>\n";
    }
}

&main::MainLoop1(0);

$id = 0;
foreach my $file (@{$all{files}})
{
    next if $file !~ /^$fltre$/;
    next unless canDoFile("$adr/$file");
    next if "$base/notes/fc-history.txt" eq "$adr/$file";
    my $size = &main::fsize($adr."/".$file);
    my $ssize = int($size/1024);
    my $ext = file_extension($file);
    my $note = (".$ext" eq $main::maillogExt) ? 'm' : 1;
    $id++;
    my $dblclick = 'ondblclick="popFileEditor(\''."$adr/$file".'\',\''.$note.'\');" ';
    my $fileclass = 'file m';
    if ($ext && defined *{'Archive::Extract::'.uc($ext)} ) {
        $dblclick = "ondblclick=\"unZip('$adr/$file','$p');\"";
        $fileclass = 'zfile z';
    }
    if (lc($ext) eq 'ppd') {
        $dblclick = "ondblclick=\"runPPM('$adr/$file');\"";
        $fileclass = 'ppdfile ppd';
    }
    my $title = (length($file) > 25) ? " title=\"$file\"" : '';
    $outlist .= '<tr id="rowf'.$p.$id.'" name="'.$adr.'/'.$file.','.$ssize.'"'.$title.' class="trow" '.$dblclick.'onclick="toggleItem'.$side.'(this,'."'$adr/$file'".',\'trow\',\'file\','.$ssize.');">';
    $outlist .= "<td class=\"$fileclass\">";
    $outlist .= file_name($file);
    $outlist .= "</td>";
    $outlist .= "<td name=\"ext$p\">";
    $outlist .= $ext;
    $outlist .= "</td>";
    $outlist .= "<td name=\"size$p\">";
    ${"totalsize$p"}+= &main::fsize($adr."/".$file);
    ${"totalfiles$p"}++;
    $outlist .= formNumDataSize($size);
    $outlist .= "</td>";
    $outlist .= "<td name=\"date$p\">".&main::timestring(&main::ftime($adr."/".$file),'','DD.MM.YYYY hh:mm:ss')."</td>";
    $outlist .=("</tr>\n");
    &main::MainLoop1(0) if (! $id % 50);

}

$outlist .= <<EOT;
</tbody>
</table>
</div>
</div>
EOT
return $outlist;
}

sub process {

my ( $href, $qsref ) = @_;
$head = $$href if $href;
$qs   = $$qsref if $qsref;
my %qs;
%qs = %main::qs;
$base = $main::base;
$ActWebSess = $main::ActWebSess;

if (exists $CanFile{$main::WebIP{$ActWebSess}->{user}} && $CanFile{$main::WebIP{$ActWebSess}->{user}}{'LASTTIME'} < (time - 900)) {
    delete $CanFile{$main::WebIP{$ActWebSess}->{user}};
}

$totalsizel = 0;
$totalfilesl = 0;
$totaldirsl = 0;
$totalsizer = 0;
$totalfilesr = 0;
$totaldirsr = 0;

my $fcuser = $main::WebIP{$ActWebSess}->{user}.".fc.";
my $store = \%main::AdminUsersRight;

my $sortl = $qs{sortl} || $store->{$fcuser.'sortl'} || 'nameu';
my $sortr = $qs{sortr} || $store->{$fcuser.'sortr'} || 'nameu';
our $adrl = $qs{adrl}   || $store->{$fcuser.'adrl'};
our $adrr = $qs{adrr}   || $store->{$fcuser.'adrr'};
my $filterl = $qs{filterl} || $store->{$fcuser.'filterl'} || '*';
my $filterr = $qs{filterr} || $store->{$fcuser.'filterr'} || '*';

$adrl = $base if $adrl !~ /^\Q$base\E/o;
$adrr = $base if $adrr !~ /^\Q$base\E/o;

$store->{$fcuser.'sortl'} = $sortl;
$store->{$fcuser.'sortr'} = $sortr;
$store->{$fcuser.'adrl'} = $adrl;
$store->{$fcuser.'adrr'} = $adrr;
$store->{$fcuser.'filterl'} = $filterl;
$store->{$fcuser.'filterr'} = $filterr;

my %cmd;
if ($qs{cmd}) {
    for my $entry (split(/;/o,$qs{cmd})) {
        if ($entry =~ /^([a-zA-Z0-9]+)\(([^,]+)(?:,(.+))?\)$/o) {
            fcHist($entry);
            if ($1 eq 'upload') {
                @{$cmd{'cmd_'.$1}{$2}} = (\%qs);
            } else {
                @{$cmd{'cmd_'.$1}{$2}} = split(/,/o,$3);
            }
        }
    }
}
my $cmd_error;
for my $c (keys(%cmd)) {
    for my $cm (keys (%{$cmd{$c}})) {
        chdir($base);
        eval{$cmd_error .= $c->($cm,@{$cmd{$c}{$cm}});};
        return $cmd_error if ($c eq 'cmd_upload');
        chdir($base);
        &main::MainLoop1(0);
    }
}

fcHist($cmd_error) if $cmd_error;

my $redirect;
for ('l','r') {
    if (exists $main::WebIP{$ActWebSess}->{"fc_zip_$_"}) {
        my $path = ${"adr$_"};
        my $zippath = $main::WebIP{$ActWebSess}->{"fc_zip_$_"}[1];
        my $opath = $main::WebIP{$ActWebSess}->{"fc_zip_$_"}[0];
        $opath =~ s/\/[^\/]+$//o;
        if ($main::WebIP{$ActWebSess}->{"fc_zip_$_"}[2] eq 'new') {
            ${"adr$_"} = $main::WebIP{$ActWebSess}->{"fc_zip_$_"}[1];
            $main::WebIP{$ActWebSess}->{"fc_zip_$_"}[2] = undef;
            next;
        } elsif ($path eq $opath) {
            ${"adr$_"} = $main::WebIP{$ActWebSess}->{"fc_zip_".$_}[1];
            next;
        } elsif ($path =~ /^\Q$zippath\E/) {
            next;
        } else {
            my $file = ${"adr$_"} = $main::WebIP{$ActWebSess}->{"fc_zip_".$_}[0];
            ${"adr$_"} =~ s/\/[^\/]+$//o;

            my $newzip = file_zip($file,"$base/tmp/$ActWebSess$_","$base/tmp/$ActWebSess$_");
            chdir($base);
            cmd_delete("$base/tmp/$ActWebSess$_",'');

            if ($newzip) {
                fcHist("possibly modified $file");
                if (eval{require File::Compare} && File::Compare::compare($file,$newzip) == 0) {
                    chdir($base);
                    $main::unlink->($newzip);
                } else {
                    chdir($base);
                    $main::unlink->($file);
                    eval{$main::rename->($newzip,$file);};
                }
            }
            chdir($base);

            delete $main::WebIP{$ActWebSess}->{"fc_zip_$_"};
            $redirect = 1;
            next;
        }
    }
}

if ($redirect) {
    return <<EOT;
HTTP/1.1 200 OK
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="refresh" content="0; URL=?adrl=$adrl&amp;sortl=$sortl&amp;adrr=$adrr&amp;sortr=$sortr&amp;filterr=$filterr">
</head>
<body>
</body>
</html>
EOT
}

getDriveInfo($adrl,'l');
getDriveInfo($adrr,'r');
$freespace_kbl ||= 0;
$totalspace_kbl ||= 0;
$freespace_kbr ||= 0;
$totalspace_kbr ||= 0;

my $title="SPAMBOX file Commander $VERSION at $main::localhostname - SPAMBOX $main::MAINVERSION - User: ".$main::WebIP{$ActWebSess}->{user};
my $Jscript  = "var mailext = '$main::maillogExt';\n";
   $Jscript .= "var sessionid = '$ActWebSess';\n";
   $Jscript .= "var spamboxbase = '$base/';\n";
open(my $F, '<', "$base/images/fc.js") or return "ERROR: can not open $base/images/fc.js - $!";
binmode $F;
$Jscript .= join('',<$F>);
close $F;

$out = <<EOT;
HTTP/1.1 200 OK
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$title</title>
<meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
<meta content="en" http-equiv="content-language" />
<meta content="Thomas Eckardt" name="author" />
<meta content="2013" name="copyright" />
<link rel="stylesheet" href="get?file=images/fc.css" type="text/css" title="fc" media="screen,tv,projection"/>
<script type=\"text/javascript\">
<!--
$Jscript
// -->
</script>
</head>
<body>
EOT

defined *{'main::yield'} || undef $out;
$out .= <<EOT;
<div class="wait" id="wait" style="display: none;">&nbsp;&nbsp; Please wait while loading... &nbsp;&nbsp;</div>
<div id="frame">
  <div class="list-top m">
   <p><strong>$title</strong></p>
   <span class="right">
    <a href="JavaScript:void();" class="win min" title="minimize?" onclick="window.moveTo(3000,3000);window.resizeTo(10,10);window.blur();">_</a>
    <a href="./logout" class="win close" title="logout?">X</a>
   </span>
  </div>
  <div id="list-menu">
   <p>
    <a href="JavaScript:void();" title="not available in this version">Files</a>
    <a href="JavaScript:void();" title="not available in this version">Mark</a>
    <a href="JavaScript:void();" title="not available in this version">Commands</a>
    <a href="JavaScript:void();" title="not available in this version">Net</a>
    <a href="JavaScript:showLog();" title="show the file commander log file">Show Log</a>
    <a href="JavaScript:openConfig();" title="open the SPAMBOX configuration page">Configuration</a>
    <a href="JavaScript:void();" title="not available in this version">Start</a>
    <span class="right"><a href="http://spambox.cvs.sourceforge.net/viewvc/spambox/spambox2/filecommander/readme.html" target="_blank">help</a></span>
   </p>
  </div>
  <div id="panel">
  <p><a href="JavaScript:location.reload(true);" id="refresh" class="m" title="Refresh"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:doSelect('l');" id="i1" class="i1" title="select left"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:unSelect('l');" id="i2" class="i2" title="unselect left"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:toggleSelect('l');" id="i3" class="i3" title="toggle select left"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:setFilter('l');" id="i4" class="i4" title="set display filter"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:delFilter('l');" id="i5" class="i5" title="remove display filter"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:void();" id="in" class="in" title=""></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:void();" id="in" class="in" title=""></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:void();" id="in" class="in" title=""></a><span class="refresh"><!-- --></span></p>
  <p><input type="checkbox" checked id="i9" class="i9" title="show/hid extension column" onclick="JavaScript:toggleColSel(this,'extl');"><span class="refresh"><!-- --></span></p>
  <p><input type="checkbox" checked id="i9" class="i9" title="show/hid size column" onclick="JavaScript:toggleColSel(this,'sizel');"><span class="refresh"><!-- --></span></p>
  <p><input type="checkbox" checked id="i9" class="i9" title="show/hid date and time column" onclick="JavaScript:toggleColSel(this,'datel');"><span class="refresh"><!-- --></span></p>

  <p><a href="JavaScript:location.reload(true);" id="refresh" class="m" title="Refresh"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:doSelect('r');" id="i1" class="i1" title="select right"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:unSelect('r');" id="i2" class="i2" title="unselect right"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:toggleSelect('r');" id="i3" class="i3" title="toggle select right"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:setFilter('r');" id="i4" class="i4" title="set display filter"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:delFilter('r');" id="i5" class="i5" title="remove display filter"></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:void();" id="in" class="in" title=""></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:void();" id="in" class="in" title=""></a><span class="refresh"><!-- --></span></p>
  <p><a href="JavaScript:void();" id="in" class="in" title=""></a><span class="refresh"><!-- --></span></p>
  <p><input type="checkbox" checked id="i9" class="i9" title="show/hid extension column" onclick="JavaScript:toggleColSel(this,'extr');"><span class="refresh"><!-- --></span></p>
  <p><input type="checkbox" checked id="i9" class="i9" title="show/hid size column" onclick="JavaScript:toggleColSel(this,'sizer');"><span class="refresh"><!-- --></span></p>
  <p><input type="checkbox" checked id="i9" class="i9" title="show/hid date and time column" onclick="JavaScript:toggleColSel(this,'dater');"><span class="refresh"><!-- --></span></p>
  </div>
  <div id="leftmenu-full">
   <select name="disk">
    <option title="">[-$main::localhostname-]</option>
<!--
    <option title="$main::localhostname">[-$main::MAINVERSION-]</option>
    <option title="drive">[-c-]</option>
    <option title="drive">[-d-]</option>
    <option title="network">[-/-]</option>
// -->
   </select>
   <p class="left">$voll $freespace_kbl k of $totalspace_kbl k free</p>
   <div class="right-dir-up">
    <span class="refresh"><!-- --></span>
    <a href="?adrl=$base&amp;sortl=$sortl&amp;adrr=$adrr&amp;sortr=$sortr&amp;filterr=$filterr" title="">/</a>
    <span class="refresh"><!-- --></span>
    <a href="l_switch..to..updir_l" title="">..</a>
   </div>
  </div>

  <div id="rightmenu-full">
   <select name="disk">
    <option title="">[-$main::localhostname-]</option>
<!--
    <option title="$main::localhostname">[-$main::MAINVERSION-]</option>
    <option title="drive">[-c-]</option>
    <option title="drive">[-d-]</option>
    <option title="network">[-/-]</option>
// -->
   </select>
   <p class="left">$volr $freespace_kbr k of $totalspace_kbr k free</p>
   <div class="right-dir-up">
    <span class="refresh"><!-- --></span>
    <a href="?adrr=$base&amp;sortr=$sortr&amp;adrl=$adrl&amp;sortl=$sortl&amp;filterl=$filterl" title="">/</a>
    <span class="refresh"><!-- --></span>
    <a href="r_switch..to..updir_r" title="">..</a>
   </div>
  </div>
EOT

$out .= fillSide('left',$adrl,$sortl,$filterl,"adrr=$adrr&amp;sortr=$sortr&amp;filterr=$filterr&amp;");
$out .= fillSide('right',$adrr,$sortr,$filterr,"adrl=$adrl&amp;sortl=$sortl&amp;filterl=$filterl&amp;");

$out .= <<EOT;
<div id="middle" title="50.0%"></div>

<div id="leftmenu-def">
<p><strong>
EOT
$out .= '<b id="filesizel">0</b>';
$out .= 'kb / '. formNumDataSize($totalsizel).' in <b id="filecountl">0</b> / '.$totalfilesl.' files, <b id="dircountl">0</b> / '.$totaldirsl.' dir(s)</strong></p>';

$out .= <<EOT;
</div>

<div id="rightmenu-def">
 <p><strong>
EOT
$out .= '<b id="filesizer">0</b>';
$out .= 'kb / '. formNumDataSize($totalsizer).' in <b id="filecountr">0</b> / '.$totalfilesr.' files, <b id="dircountr">0</b> / '.$totaldirsr.' dir(s)</strong></p>';
$out .= <<EOT;
</div>

 <div id="f-keys">
  <ul>
   <li><a href="JavaScript:actionView();" title="">View</a></li>
   <li><a href="JavaScript:actionEdit();" title="">Edit</a></li>
   <li><a href="JavaScript:actionCopy('$adrl','$adrr');" title="">Copy</a></li>
   <li><a href="JavaScript:actionMove('$adrl','$adrr');" title="">Move</a></li>
   <li><a href="JavaScript:actionRename();" title="">Rename</a></li>
   <li><a href="JavaScript:actionDelete();" title="">Delete</a></li>
   <li><a href="JavaScript:actionNewDir('$adrl');" title="">New left Folder</a></li>
   <li><a href="JavaScript:actionNewDir('$adrr');" title="">New right Folder</a></li>
  </ul>
 </div>
 <div id="f-keys">
  <ul>
   <li><a href="JavaScript:actionAnalyze();" title="">Analyze $main::maillogExt</a></li>
   <li><a href="JavaScript:actionZip('$adrl','$adrr');" title="zip left selected">ZIP left</a></li>
   <li><a href="JavaScript:actionDownload();" title="download one left file">download</a></li>
   <li><a href="JavaScript:actionUpload('$adrl');" title="upload one file to the left">upload</a></li>
   <li><a href="JavaScript:void();" title="">&nbsp;</a></li>
   <li><a href="JavaScript:void();" title="">&nbsp;</a></li>
   <li><a href="JavaScript:void();" title="">&nbsp;</a></li>
   <li><a href="./logout" title="logout">Logout</a></li>
  </ul>
 </div>
 </div>
 <form name="TCCMD" id="TCCMD" action="" method="post">
   <input id="cmd" name="cmd" type="hidden" value="" />
 </form>
<script type=\"text/javascript\">
<!--
adjustTableCols();
// -->
</script>
EOT
if ($cmd_error) {
$cmd_error =~ s/\\/\//go;
$cmd_error =~ s/\r?\n/ \\\n/gos;
$out .= <<EOT;
<script type=\"text/javascript\">
<!--
alert('$cmd_error');
// -->
</script>
EOT
}
$out .= <<EOT;
</body>
</html>
EOT
defined *{'main::yield'} || undef $out;
return $out;

}

sub cmd_copy {
    my ($from,$to) = @_;
    my $error;
    return if $from =~ /\/\.{1,2}$/;
    if ($main::dF->($from)) {
        my ($flr) = $from =~ /(\/[^\/]+)$/o;
        if (canDoFile($to.$flr.'/')) {
            eval{$main::mkdir->($to.$flr,0755);};
            $error .= cmd_copy("$from/$_",$to.$flr) for $main::unicodeDH->($from);
        } else {
            $error .= "permission denied for $to$flr";
        }
    } elsif ($main::eF->($from)) {
        my ($fn) = $from =~ /\/([^\/]+)$/o;
        eval {
            die "permission denied for $from or $to/$fn\n" if (! canDoFile($from) || ! canDoFile("$to/$fn"));
            $main::copy->($from,$to)
        };
        $error .= "unable to copy '$from' to '$to' - $@ - $!\n" if $@;
    }
    return $error;
}                          ;

sub cmd_move {
    my ($from,$to) = @_;
    my $error;
    if ($main::dF->($from)) {
        $error .= cmd_delete($from,'') unless ($error = cmd_copy($from,$to));
    } elsif ($main::eF->($from)) {
        my ($fn) = $from =~ /\/([^\/]+)$/o;
        eval{die "no permission to $from or $to/$fn\n" if (! canDoFile($from) || ! canDoFile("$to/$fn")); $main::move->($from,$to)};
        $error .= "unable to move '$from' to '$to' - $@ - $!\n" if $@;
    }
    return $error;
}

sub cmd_create {
    my $file = shift;
    my $dummy = shift;
    my $error;
    if ($main::dF->($file)) {
        $error .= "folder '$file' already exists\n";
    } elsif ($main::eF->($file)) {
        $error .= "a file with the name '$file' already exists\n";
    } else {
        eval{$main::mkdir->($file,0755);};
        $error .= "unable to create folder '$file' - $@ - $!\n" if $@;
    }
    return $error;
}

sub cmd_delete {
    my ($file,$dummy) = @_;
    my $error;
    chdir($base);
    if ($main::dF->($file)) {
        eval{$main::rmtree->($file);};
        if ($@) {
            $error .= "$@ - $!\n";
            if ($^O eq 'MSWin32' && $main::canUnicode && eval('use File::Path 2.00 ();1;')) {
                eval{File::Path::remove_tree($file);};
                $error = $@;
            }
        }
    } elsif ($main::eF->($file)) {
        eval{$main::unlink->($file);};
        $error .= "$@ - $!\n" if $@;
    } else {
        $error .= "unable to find '$file'\n";
    }
    chdir($base);
    return $error;
}

sub cmd_rename {
    my $file = shift;
    my $re = shift;
    my ($dir,$name) = $file =~ /^(.*\/)([^\/]+)$/o;
    my @nchars = split(//o,$name);
    my @rchars = split(//o,$re);
    my @newname;
    for (@nchars) {
        my $r = shift(@rchars);
        if ($r =~ /[*?]/o) {
            if ($rchars[0] ne $_) {
                push(@newname,$_);
                unshift(@rchars,$r) if $r eq '*';
            } else {
                push(@newname,$_);
                shift(@rchars);
            }
        } else {
            push(@newname,$r);
        }
        last unless (@rchars)
    }
    while (my $c = shift(@rchars)) {
        push(@newname,$c) if $c !~ /[*?]/o;
    }
    my $error;
    my $newfile = $dir.join('',@newname);
    if ( canDoFile($dir.$name) && ($main::dF->($dir.$name) || $main::eF->($dir.$name))) {
        eval{$main::rename->($file,$newfile);};
        $error .= "$@ - $!\n" if $@;
    } else {
        $error .= "unable to find '$file' or permission denied\n";
    }
    return $error;
}

sub cmd_unzip {
    my $file = shift;
    my $site = shift;
    my $error;
    my $ae = Archive::Extract->new( archive => $file );
    cmd_delete("$base/tmp/$ActWebSess$site",'');
    mkdir "$base/tmp/$ActWebSess$site", 0755;
    my $ok = $ae->extract( to => "$base/tmp/$ActWebSess$site" ) or $error = $ae->error."\n";
    chdir($base);
    unless ($ok) {
        $error .= cmd_delete("$base/tmp/$ActWebSess$site",'');
        return $error;
    }
    $main::WebIP{$ActWebSess}->{"fc_zip_$site"} = [$file,"$base/tmp/$ActWebSess$site",'new'];
    return $error;
}

sub cmd_zip {
    my ($file,$basedir,@src) = @_;
    my $newzip = file_zip($file,$basedir,@src);
    if ($newzip) {
        chdir($base);
        $main::unlink->($file);
        eval{$main::rename->($newzip,$file);};
        return;
    }
    return "an error occured while compressing";
}

sub file_zip {
    my ($file,$basedir,@src) = @_;
    return unless @src;
    return unless $file;
    my ($ext, $preext);
    ($preext, $ext) = (lc($1),lc($2)) if $file =~ /^.+?(?:\.([^.]+))?\.([^.]+)$/;
    return if $ext !~ /^(?:zip|gz(?:ip)?|bz(?:2|ip)?|t[gb]z)$/o;
    my @filelist = fileList(@src);
    return if (scalar(@filelist) > 1 && $preext ne 'tar' && $ext =~ /^(?:gz(?:ip)?|bz(?:2|ip)?)$/o);
    my $newzip = $file.".tmp~";
    if ($ext eq 'zip') {
        my $zip = -e $file ? Archive::Zip->new($file) : Archive::Zip->new();
        eval{
            chdir $basedir if $basedir;
            for (@filelist) {
                s/^\Q$basedir\E\/// if $basedir;
                if (-d $_) {$_ .= '/';}
            }
            for (@src) {
                $_ = undef unless canDoFile($_);
                if (-d $_) {$_ .= '/'; $_ = undef unless canDoFile($_);}
            }
            if (-e $file) {
                $zip->updateTree( $_, '', undef , 1 ) for @src;
            } else {
                $zip->addFileOrDirectory( $_ ) for @src;
            }
            $zip->writeToFileNamed($newzip);
            1;
        } or do {
            $zip = undef;
            $main::unlink->($newzip);
            $newzip = undef;
        };
        return $newzip;
    } elsif ($ext =~ /^(?:gz(?:ip)?|bz(?:2|ip)?)$/o && $preext ne 'tar') {
        my $mode = ($ext =~ /g/o) ? 'IO::Compress::Gzip::gzip' : 'IO::Compress::Bzip2::bzip2';
        chdir $basedir if $basedir;
        for (@filelist) {
            s/^\Q$basedir\E\/// if $basedir;
        }
        return $newzip if $mode->($filelist[0],$newzip);
        return;
    } elsif (($ext =~ /^(?:gz(?:ip)?|bz(?:2|ip)?)$/o && $preext eq 'tar') || $ext =~ /^t[gb]z$/o) {
        my $mode = ($ext =~ /g/o) ? COMPRESS_GZIP : COMPRESS_BZIP;
        chdir $basedir if $basedir;
        for (@filelist) {
            s/^\Q$basedir\E\/// if $basedir;
        }
        return $newzip if Archive::Tar->create_archive( $newzip, $mode, @filelist );
        return;
    } else {
        mlog(0,"SPAMBOX_FC: no possible compression methode found for $newzip");
    }
}

sub cmd_runPPM {
    my $file = shift;
    my $dummy = shift;
    my $cmd = "ppm install $file 2>&1";
    mlog(0,"request: FC request from ".$main::WebIP{$ActWebSess}->{user}." : $cmd");
    my $out = qx($cmd);
    mlog(0,"result: FC request from ".$main::WebIP{$ActWebSess}->{user}." : $cmd\n$out");
    return $out;
}

sub cmd_upload {
my ($targetDir,$file,@src) = @_;
my $res;
if ($head =~ s/^post [^\r\n]+\r?\n//ios && $qs =~ s/^cmd=.+?;&//ios) {
    my $om = $main::o_EMM_pm;
    $main::o_EMM_pm = 1;
    $Email::MIME::ContentType::STRICT_PARAMS=0;
    my $html = Email::MIME->new("$head\r\n$qs");
    foreach my $part ( $html->parts ) {
        my $dis = $part->header("Content-Disposition") || '';
        my $attrs = $dis =~ s/^[^;]*;//o ? Email::MIME::ContentType::_parse_attributes($dis) : {};
        my $filename = $attrs->{filename} || $part->{ct}{attributes}{filename} || $part->filename;
        ($filename) = $dis =~ /filename=["']?([^\r\n"']+)/io unless $filename;
        $filename = &main::decodeMimeWords($filename);
        last unless canDoFile("$targetDir/$filename");
        if ($filename && $main::open->(my $F, '>', "$targetDir/$filename")) {
            binmode($F);
            print $F $part->body;
            close $F;
            
            $res = "<br /><br />file: '$targetDir/$filename' uploaded - ".formNumDataSize(&main::fsize("$targetDir/$filename"));
        } else {
            $res = "<br /><br />failed to upload '$targetDir/$filename'";
        }
    }
    $main::o_EMM_pm = $om;
}
return <<EOT
HTTP/1.1 200 OK
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>SPAMBOX File Upload</title>

    <style type="text/css">
      html, body
      {
        padding-top: 0.5em;
        padding-bottom: 0.5em;
        padding-left: 0.5em;
        padding-right: 0.5em;
        margin: 0px;
      }
      #author
      {
        top: 0px;
        text-align: center;
        position: fixed;
        width: 100%;
        margin-left: -1em;
        margin-right: -0.5em;
        border: 1px solid back;
        background: blue;
      }
    </style>

    <script type="text/javascript">
      function checkForm()
      {
          var input = document.getElementById("file_input");

          if ( input.files.length < 1 )
          {
            alert("Please select a file!");
            return;
          }
          document.getElementById("status").innerHTML = "Processing";
          document.getElementById("form").submit();
      }
    </script>
  </head>

  <body>
    <div id="author">By Thomas Eckardt &nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;&copy; Thomas Eckardt, 2013 &nbsp;&nbsp;&nbsp;&bull;</div>
    <br />
    <h1>SPAMBOX File upload to $targetDir</h1>

    <hr />
    Status: <span id="status">Ready</span>
    <hr />

    <form id="form" action="" method="post" enctype="multipart/form-data">
      <input type="file" id="file_input" name="uploadfile"/>
    </form>
    <br />
    <button type="button" id="btnUpload" onclick="checkForm();">Upload File</button>
    $res
  </body>
</html>
EOT
}

1;
