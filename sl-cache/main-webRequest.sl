#line 1 "sub main::webRequest"
package main; sub webRequest {
    my ($tempfh,$fh,$h,$d)=@_;
    my $data; $data = $$d if $d;
    my $head; $head = $$h if $h;
    my $k;
    my $v;
    my %webRequests = %webRequests;
    delete $webRequests{'/top10stats'} unless $DoT10Stat;

    my $i=0;
    # %head -- public hash
    (%head)=map{++$i % 2 ? lc $_ : $_} map{/^([^ :]*)[: ]{0,2}(.*)/o} split(/\r\n/o,$head);
#$head{'user-agent'};

    if (   $head{'user-agent'} =~ m/android.+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|meego.+mobile|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/io
        || substr($head{'user-agent'}, 0, 4) =~ m/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a\swa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r\s|s\s)|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)
        |em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1\su|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp(\si|ip)|hs\-c|ht(c(\-|\s|_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac(\s|\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt(\s|\/)|klon|kpt\s|kwc\-|kyo(c|k)|le(no|xi)|lg(\sg|\/(k|l|u)|50|54|\-[a-w])
        |libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-|\s|o|v)|zz)|mt(50|p1|v\s)|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)
        |qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v\s)|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)
        |vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-|\s)|webc|whit|wi(g\s|nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/xio) {

        $mobile = 1;   # this is a mobile device
    } else {
        $mobile = 0;   # this is NOT a mobile device
    }

    my ($page,$qs)=($head{get} || $head{head} || $head{post})=~/^([^\? ]+)(?:\?(\S*))?/o;
    $currentPage = $page;
    $currentPage =~ s/^\/+//o;
    $currentPage = 'Config' unless $currentPage;
    $currentPage = ucfirst($currentPage);
    $headers =~ s/<title>\S+ SPAMBOX/<title>$currentPage SPAMBOX/o if $page ne '/get' && exists $webRequests{$page};
    if(defined $data) { # GET, POST order
        $qs.='&' if ($qs ne '');
        $qs.=$data;
    }
    $qs=~y/+/ /;
    $i=0;

    # parse query string, get rid of google autofill
    # %qs -- public hash
    (%qs)=map{my $t = $_; $t =~ s/(e)_(mail)/$1$2/gio if ++$i % 2; $t} split(/[=&]/o,$qs);
    while (($k,$v) =  each %qs) {$qs{$k}=~s/%([0-9a-fA-F]{2})/pack('C',hex($1))/geo}
    my $ip=$fh->peerhost();
    my $port=$fh->peerport();
    my ($SessionID,$cert,$certowner,$enc);
    if ("$fh" =~ /SSL/oi && ($cert = ${*$fh}{'my_SSL_certificate'} || eval{$fh->dump_peer_certificate();})) {
        ${*$fh}{'my_SSL_certificate'} = $cert;
        $cert = Digest::MD5::md5_hex($cert);
        $certowner = ${*$fh}{'my_SSL_certificate_owner'} || $fh->peer_certificate('owner');
        ${*$fh}{'my_SSL_certificate_owner'} = $certowner;
    }
    $enc = SPAMBOX::CRYPT->new($Config{webAdminPassword},0) if $webSSLRequireCientCert && $SSLWEBCertVerifyCB && $cert;
    my ($auth)=$head{authorization}=~/Basic (\S+)/io;
    my ($user,$pass) = split(/:/o,base64decode($auth));
    if ($webSSLRequireCientCert && $SSLWEBCertVerifyCB && $cert && @ExtWebAuth && !$user) {
        ($user,$pass) = @ExtWebAuth;
        @ExtWebAuth = ();
        $pass ||= $AdminUsers{$user} if $user ne 'root';
        $webAuthStore{$cert} = [$user,$enc->ENCRYPT($pass)];
        my %tmp = $certowner =~ /\/([^=]+)=([^\/]*)/go;
        mlog(0,"adminuser $user authenticated for admin connection for page $page using a valid certificate owned by $tmp{CN} , $tmp{emailAddress}") if $page !~ /get|logout/io;
    } elsif (!($webSSLRequireCientCert && $SSLWEBCertVerifyCB)) {
        %webAuthStore = ();
    }
    my $passFromStore;
    if ($cert && exists $webAuthStore{$cert} && !$pass) {
        ($user,$pass) = @{$webAuthStore{$cert}};
        $pass = $enc->DECRYPT($pass);
        $passFromStore = 1;
    }
    if (! $user) {
        ($user,$pass) = split(/:/o,base64decode($auth));
        $passFromStore = undef;
    }

    if (!($cert && exists $webAuthStore{$cert}) && $user eq 'root' && substr($Config{webAdminPassword}, 0, 2) eq "45" && $pass) {
        $pass=crypt($pass,"45");
    } elsif ($cert && exists $webAuthStore{$cert} && $user eq 'root' && ! $pass) {
        $pass = $Config{webAdminPassword};
        $webAuthStore{$cert} = [$user,$enc->ENCRYPT($pass)];
    } elsif ($user eq 'root' && substr($Config{webAdminPassword}, 0, 2) eq "45" && $pass) {
        $pass=crypt($pass,"45") if ! $passFromStore;
    }

    my $sessionCookie = $head{'cookie'};
    $sessionCookie = '' unless($sessionCookie =~ s/.*?(session-id=\"[a-zA-Z0-9]+\").*/$1/io);
    my $cookie = Digest::MD5::md5_hex(Time::HiRes::time() . $TransferTime . $port . $TransferCount . $ip . $nextLoop2);
    $SessionID = Digest::MD5::md5_hex($head{'user-agent'} . $ip . $head{'host'} . $sessionCookie . $page) if ($sessionCookie or ($user && $pass && $httpRequireCookies));

    if ($SessionID && $WebIP{$SessionID}->{isauth} && !$user) {
        $user = $WebIP{$SessionID}->{user};
        if ($user eq 'root') {
            $pass = $Config{webAdminPassword};
        } else {
            $pass = $AdminUsers{$user} if $user;
        }
    }

    if (! $SessionID && $user && $pass && $httpRequireCookies) {
        print $tempfh "HTTP/1.1 200 OK
Content-type: text/html


<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body><h1>please enable cookies for this URL in your browser or disable httpRequireCookies in the spambox configuration</h1>
</body></html>\n";
        return 1;
    }

    $SessionID = Digest::MD5::md5_hex($head{'user-agent'} . $ip . $head{'host'} . $page) if ($user && $pass && ! $SessionID);

    $WebIP{$SessionID}->{cert} = $cert if $cert;
    
    if (exists $WebIP{$SessionID}->{mobile}) {
       $mobile = $WebIP{$SessionID}->{mobile};
    }
    if (exists $qs{mobile}) {
       $WebIP{$SessionID}->{mobile} = $mobile = ($qs{mobile} ? 1 : 0);
    }

    if ($user ne 'root') {
      if (&WebAuth($user,$pass)) {
        if ($page!~/pwd|get|logout/io && ($AdminUsersRight{"$user.user.passwordExp"} or           # password expired ?
           ($AdminUsersRight{"$user.user.passwordExpInt"} &&
            time > 24 * 3600 * $AdminUsersRight{"$user.user.passwordExpInt"} + $AdminUsersRight{"$user.user.passwordLastChange"}))) {
            print $tempfh "HTTP/1.1 200 OK
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
<head><meta http-equiv=\"Refresh\" content=\"1; URL=./pwd\">
</head><body></body></html>\n";
           $WebIP{$SessionID}->{ip} = $ip;
           return 1;
        }
        $WebIP{$SessionID}->{ip} = $ip;
        $WebIP{$SessionID}->{port} = $port;
        $WebIP{$SessionID}->{isauth} = 1;
        $WebIP{$SessionID}->{user} = $user;
      } else {
        delete $WebIP{$SessionID};
        my $how = ($page!~/logout/io) ? 'Unauthorized request!' : '<br />You are logged out from spambox.<br /><br />Please close the browser session!';
        print $tempfh "HTTP/1.1 401 Unauthorized
Set-Cookie: session-id=\"$cookie\";Max-Age=900;Version=\"1\";Discard;
WWW-Authenticate: Basic realm=\"Anti-Spam SMTP Proxy (SPAMBOX) Configuration\"
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body><h1>$how</h1>
</body></html>\n";
        return 0;
      }
    }

    if($pass eq $webAdminPassword && $user eq 'root') {
        $rootlogin = time;
        $WebIP{$SessionID}->{rootlogin} = $rootlogin;
    } elsif ($rootlogin) {
        if ($user && $pass) {
            my $rootip;
            foreach (keys %WebIP) {
                if ($WebIP{$_}->{user} eq 'root') {
                    if ($WebIP{$_}->{rootlogin} < time - 900) {
                        delete $WebIP{$_};
                    } else {
                        $rootip = $WebIP{$_}->{ip};
                    }
                }
            }
            if ($rootip) {
                print $tempfh "HTTP/1.1 200 OK
Content-type: text/html


<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body><h1>user root is currently logged on from host $rootip - no new sessions will be accepted until root has logged off<br /><br />please try again later</h1>
</body></html>\n";
                return 1;
            } else {
                $rootlogin = 0;
            }
        }
    }

    if(($pass eq $webAdminPassword && $user eq 'root') or $WebIP{$SessionID}->{isauth}){
        $WebIP{$SessionID}->{isauth} = 1;
        $WebIP{$SessionID}->{lastaccess} = time;
        $WebIP{$SessionID}->{user} = $user;
        $WebIP{$SessionID}->{blocking} = $qs{blocking} if exists $qs{blocking};
        $ActWebSess = $SessionID;
        $WebIP{$SessionID}->{ip} = $ip;
        $WebIP{$SessionID}->{port} = $port;
        $WebIP{$SessionID}->{changedLang} = 0;
        if (($page eq '/' || $page eq '') && ($user ne $lastRenderedUser || ! $qs{languageFile} || $qs{languageFile} ne $WebIP{$SessionID}->{languageFile})) {
            $WebIP{$SessionID}->{changedLang} = 1;
            if ($qs{languageFile} ne 'default' || ($user ne 'root' && $AdminUsersRight{"$user.user.languageFile"} ne 'default')) {
                local $/ = "\n";
                my $langF;
                if ($qs{languageFile} && $qs{languageFile} ne 'default') {
                    $langF = $qs{languageFile};
                } elsif (! $qs{languageFile}) {
                    if ($user ne 'root') {
                        $langF = $AdminUsersRight{"$user.user.languageFile"};
                    } else {
                        $langF = 'default';
                    }
                } else {
                    $langF = $qs{languageFile};
                }
                my $langFile;
                if ($langF ne 'default') {
                    $langFile = "$base/language/" . $langF;
                }
                if ($langFile &&
                    (open my $DEF, '<',"$langFile"))
                {
                  if ($langF ne $WebIP{$SessionID}->{languageFile})
                  {
                    $WebIP{$SessionID}->{languageFile} = $langF;
                    %{$WebIP{$SessionID}->{lng}} = ();
                    $AdminUsersRight{"$user.user.languageFile"} = $WebIP{$SessionID}->{languageFile} unless $user eq 'root';
                    $qs{languageFile} = $WebIP{$SessionID}->{languageFile};
                    my $msg;
                    my $cont;
                    while (my $line = (<$DEF>)) {
                        $line =~ s/\r//go;
                        $line =~ s/\n//go;
                        next unless $line;
                        next if $line =~ /^\s*[#;]/o;
                        if ($line =~ /^\s*(msg[^01]\d{5})\s*=\s*(.*)/o) {
                            my $l1 = $1;
                            my $l2 = $2;
                            if ($msg) {
                               my $i = 0;
                               my %v = ();
                               while ($cont =~ s/(\$[a-zA-Z][a-zA-Z0-9_{}\[\]\-\>]+)/\[\%\%\%\%\%\]/o) {
                                   my $var = $1;
                                   $v{$i} = eval($var);
                                   $v{$i} = $var unless defined $v{$i};
                                   $i++;
                               }
                               $i = 0;
                               while ($cont =~ s/\[\%\%\%\%\%\]/$v{$i}/o) {$i++}
                               $WebIP{$SessionID}->{lng}->{$msg} = $cont;
                               $cont = '';
                            }
                            $msg = $l1;
                            $cont = $l2."\n";
                        } else {
                            $cont .= $line."\n";
                        }
                    }
                    $WebIP{$SessionID}->{lng}->{$msg} = $cont if $msg && $cont;
                  } # endif lang changed
                  close $DEF;
                } else {  # open langfile failed
                    $AdminUsersRight{"$user.user.languageFile"} = 'default' unless $user eq 'root';
                    $qs{languageFile} = 'default';
                    $WebIP{$SessionID}->{languageFile} = 'default';
                    %{$WebIP{$SessionID}->{lng}} = ();
                }
            } else { # langfile not set
                $AdminUsersRight{"$user.user.languageFile"} = 'default' unless $user eq 'root';
                $qs{languageFile} = 'default';
                $WebIP{$SessionID}->{languageFile} = 'default';
                %{$WebIP{$SessionID}->{lng}} = ();
            }
            $lastRenderedUser = $user;
        }

        if ($page!~/shutdown_frame|shutdown_list|favicon.ico|get|statusspambox/io){

            # only count requests for pages without meta refresh tag
            # dont count requests for favicon.ico file
            # dont count requests for 'get' page
            my $args;
            if ($page=~/edit/io) {
                if (defined($qs{contents})) {
                    if ($qs{B1}=~/delete/io) {
                        $args="deleting file:$qs{file}";
                    }
                    else {
                        $args="writing file:$qs{file}";
                    }
                }
                else {
                    $args="reading file:$qs{file}";
                }
            }
            my $sessInfo = "$ip:$port; page:$page;";
            $sessInfo .= " args;" if $args;
            $sessInfo .= " session-ID:$SessionID;" if $SessionLog;
            $sessInfo .= ($mobile ? " mobile device;" : '') if $SessionLog;
            mlog(0,"admin connection from user $user on host $sessInfo");

            $Stats{admConn}++;
        } elsif ($SessionLog > 1 && $page=~/shutdown_frame|shutdown_list|statusspambox/io) {
            my $sessInfo = "$ip:$port; page:$page;";
            $sessInfo .= " session-ID:$SessionID;";
            $sessInfo .= ($mobile ? " mobile device;" : '');
            mlog(0,"admin connection from user $user on host $sessInfo");
        }
        if ($page=~/adminusers/io){
            unless ($user eq 'root') {
                return &webBlock($tempfh);
            }
        }
        if ($page=~/quit/io){
            if ($user eq 'root' or &canUserDo($user,'action','quit')) {
                ConfigQuit($tempfh);
            } else {
                return &webBlock($tempfh);
            }
        }
        if ($page=~/suspendresume/io){
            if ($user eq 'root' or &canUserDo($user,'action','suspendresume')) {
                ConfigSuspendResume();
            } else {
                return &webBlock($tempfh);
            }
        }
        if ($page=~/logout/io){
            WebLogout($fh);
            return 1;
        }
        if ( $page =~ /reload/io ) {
            if ($user eq 'root' or &canUserDo($user,'action','reload')) {
                reloadConfigFile();
            } else {
                return &webBlock($tempfh);
            }
        }
        if ( $page =~ /save/io ) {
            if ($user eq 'root' or &canUserDo($user,'action','save')) {
                SaveConfig();
            } else {
                return &webBlock($tempfh);
            }
        }
        if ( $page =~ /syncedit/io ) {
            unless ($user eq 'root' or &canUserDo($user,'action','syncedit')) {
                return &webBlock($tempfh);
            }
        }
        if ($page=~/favicon.ico/io){
            print $tempfh "HTTP/1.1 404 Not Found
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body><h1>Not found</h1>
</body></html>\n";
        } else {
            if ($user eq 'root' or &canUserDo($user,'action',lc($page))) {
                print $tempfh ((defined ($v=$webRequests{lc $page}))? $v->(\$head,\$qs): webConfig(\$head,\$qs));
            } else {
                return &webBlock($tempfh);
            }
        }
    } else {
        print $tempfh "HTTP/1.1 401 Unauthorized
Set-Cookie: session-id=\"$cookie\";Max-Age=900;Version=\"1\";Discard;
WWW-Authenticate: Basic realm=\"Anti-Spam SMTP Proxy (SPAMBOX) Configuration\"
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body><h1>Unauthorized</h1>
</body></html>\n";
    }
    return 1 if (lc $page ne '/shutdown_list' && $page ne '/statusspambox');
    return 0;
}
