#line 1 "sub main::registerGlobalClient"
package main; sub registerGlobalClient {
    my $client = shift;

    my $url = allRot($globalRegisterURL);
    $url = 'http://'.$url if $url !~ m!^(?:ht|f)tps?://!io;

    my $ua = LWP::UserAgent->new();
    $ua->agent("ASSP/$version$modversion ($^O; Perl/$]; LWP::UserAgent/$LWP::VERSION)");
    $ua->timeout(20);

    if ($proxyserver) {
       my $user = $proxyuser ? "http://$proxyuser:$proxypass\@": "http://";
       $ua->proxy( 'http', $user . $proxyserver );
       mlog(0,"try register client $client on global server via proxy:$proxyserver") if $MaintenanceLog;
       my $la = getLocalAddress('HTTP',$proxyserver);
       $ua->local_address($la) if $la;
    } else {
       mlog(0,"try register client $client on global server via direct connection") if $MaintenanceLog;
       my ($host) = $url =~ /^\w+:\/\/([^\/]+)/o;
       my $la = getLocalAddress('HTTP',$host);
       $ua->local_address($la) if $la;
    }
    my $req = HTTP::Request::Common::POST ($url,Content_Type => 'multipart/form-data',
        Content => [
            ClientName => $client,   #  Client Name
            UUID => $UUID,           #  Client UUID
          ]);
    my $responds = $ua->request($req);
    my $res=$responds->content;
    if ($responds->is_success && $res =~ /password\:([^\r\n]*)\r?\n/ios) {
        $globalClientPass = $1;
        $Config{globalClientPass}=$globalClientPass;
        $globalClientName = $client;
        $Config{globalClientName}=$globalClientName;
        mlog(0,"info: successful registered client $client on global-PB server");
        if (! -e "$base/$pbdir/global/out/pbdb.white.db.gz") {
            unlink "$base/$pbdir/global/out/pbdb.black.db";
            unlink "$base/$pbdir/global/out/pbdb.black.db.gz";
            unlink "$base/$pbdir/global/out/pbdb.white.db";
        }
        if ($res =~ /registerurl:([^\r\n]+)\r?\n/ios) {
            $globalRegisterURL = &allRot($1);
            $Config{globalRegisterURL}=$globalRegisterURL;
            $ConfigAdd{globalRegisterURL} = $globalRegisterURL if exists $ConfigAdd{globalRegisterURL};
        }
        if ($res =~ /uploadurl:([^\r\n]+)\r?\n/ios) {
            $globalUploadURL = &allRot($1);
            $Config{globalUploadURL}=$globalUploadURL;
            $ConfigAdd{globalUploadURL}=$globalUploadURL if exists $ConfigAdd{globalUploadURL};
        }
        if ($res =~ /licdate\:(\d\d\d\d)(\d\d)(\d\d)\r?\n/ios) {
            $globalClientLicDate = "$3.$2.$1";
            $Config{globalClientLicDate}=$globalClientLicDate;
        }
        &SaveConfig();
        $nextGlobalUploadBlack = 0;
        $nextGlobalUploadWhite = 0;
        return 1;
    } elsif ($res =~ /error\:.*/ios) {
        $res =~ s/\r|\n//go;
        mlog(0,"warning: register client $client on global-PB server failed : $res");
        return $res;
    }
    return '';
}
