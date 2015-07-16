#line 1 "sub main::syncConfigReceived"
package main; sub syncConfigReceived {
    my $file = shift;
    return if $WorkerNumber > 0;
    $file =~ s/\\/\//go;
     # ConfigName.sprintf("%.3f",(Time::HiRes::time())).ip|host.cfg
    my ($name,$ip);
    ($name,$ip) = ($1,$2) if $file =~ /\/([^\/\.]+?)\.\d{10}\.\d{3}\.($HostRe)\.cfg$/o;

    unless ($name) {unlink $file; return;}
    unless ($ip) {unlink $file; return;}
    unless (&syncCanSync()) {unlink $file; return;}
    unless ($enableCFGShare) {unlink $file; return;}
    unless ($isShareSlave) {unlink $file; return;}
    if (exists $neverShareCFG{$name}) {unlink $file; return;}
    unless (exists $Config{$name}) {unlink $file; return;}
    my $FH;
    (-w $file && (open $FH, '<',"$file"))  or return;
    d("syncConfigReceived $file $name $ip");

    my ($var,$val,@cfg,$File,$FileCont);
    my $FileWritten = 0;

    binmode $FH;
    my $fcont = join('',<$FH>);
    close $FH;
    if (! $fcont) {
        mlog(0,"syncCFG: file '$file' for $name is empty - ignore the sync-file");
        unlink $file;
        return;
    }
    if (! ($fcont = ASSP::CRYPT->new($webAdminPassword,0)->DECRYPT(join('',$fcont)) )) {
        mlog(0,"syncCFG: no results after decrypt file '$file' for $name - ignore the sync-file");
        unlink $file;
        return;
    }
    foreach my $line (split(/\r?\n/o,$fcont)) {
        $line =~ s/\r|\n//go;
        next unless $line;
        push @cfg , MIME::Base64::decode_base64($line);
    }
    if (! @cfg) {
        mlog(0,"syncCFG: no results after BASE64-decode file '$file' for $name - ignore the sync-file");
        unlink $file;
        return;
    }
    while (@cfg) {
        my $line = shift @cfg;
        $line =~ s/(\r?\n)$//o;
        next if (! $line && ! $File);
        if ($line =~ /^\s*([a-zA-Z0-9_\-]+)\:\=(.*)$/o) {
            ($var,$val) = ($1,$2);
            if ($var ne $name) {
                mlog(0,"syncCFG: Wrong configuration variable name '$var' found - expected '$name' - ignore the sync-file");
                unlink $file;
                return;
            }
            next;
        }
        next unless $var;
        if ($line =~ /^\s*#\s*UUID\s+(.+)$/o) {
            if (ASSP::UUID::equal_uuids($UUID, $1)) {
                mlog(0,"syncCFG: error: the sending host has the same UUID like this assp installation - this is a possible license violation - ignore the sync-file");
                unlink $file;
                return;
            }
            next;
        }
        if ($line =~ /^\s*# file start (.+)$/o) {   # file start
            $File = "$base/$1";
            $File .= '.synctest' if $syncTestMode;
            next;
        }
        if ($File && !$FileNoSync{$File} && $line =~ /^\s*# file eof\s*$/o) {   # file eof
            my $currFileCont;
            if (-e $File) {
                if (open my $FileH , '<',"$File") {
                    binmode $FileH;
                    $currFileCont = join('',<$FileH>);
                    close $FileH;
                    if (exists $CryptFile{$File} && $currFileCont =~ /^(?:[a-zA-Z0-9]{2})+$/o) {
                        my $enc = ASSP::CRYPT->new($webAdminPassword,0);
                        $currFileCont = $enc->DECRYPT($currFileCont);
                    }
                }
            }
            if ($currFileCont ne $FileCont && (open my $FileH , '>',"$File")) {
                binmode $FileH;
                if (exists $CryptFile{$File}) {
                    my $enc = ASSP::CRYPT->new($webAdminPassword,0);
                    $FileCont = $enc->ENCRYPT($FileCont);
                }
                print $FileH $FileCont;
                close $FileH;
                my $text = $syncTestMode ? '[testmode] ' : '' ;
                mlog(0,"syncCFG: $text" . "wrote file $File for $name") if $MaintenanceLog;
                $FileWritten = 1;
            }
            $File = '';
            $FileCont = '';
            next;
        }
        $FileCont .= $line if $File;
    }
    if (! $var) {
        mlog(0,"syncCFG: NO configuration variable name found - expected '$name' - ignore the sync-file");
        unlink $file;
        return;
    }
    if ($File && $FileNoSync{$File}) {
        mlog(0,"syncCFG: file $File received for $var - but ignored, because the current file contains '# assp-no-sync'");
    }
    if (${$var} ne $val or $FileWritten) {
        my $ovar = ${$var};
        for my $idx (0...$#ConfigArray) {
            my $c = $ConfigArray[$idx];
            next if (! $c->[0] || @$c == 5 || $c->[0] ne $var);
            my $oqs = $qs{$var};
            $qs{$var} = $val;
            $syncUser = 'sync';
            $syncIP = $ip;
            my $Error;
            $Error = checkUpdate($var,$c->[5],$c->[6],$c->[1]) unless $syncTestMode;
            mlog(0,"syncCFG: [testmode] changed $name from '$Config{$name}' to '$val'") if $syncTestMode;
            $qs{$var} = $oqs;
            $syncUser = '';
            $syncIP = '';
            delete $qs{$var} unless defined $oqs;
            if ($Error =~ /span class.+?negative/o) {
                 mlog(0,"syncCFG: wrong value ($val) for $var found in sync file from $ip") if $MaintenanceLog;
                 unlink $file;
                 return;
            }
            if (! $ConfigChanged && $FileWritten) {
                $syncUser = 'sync';
                $syncIP = $ip;
                &optionFilesReload();
                $ConfigChanged = 1 if ($val eq $ovar);
                $syncUser = '';
                $syncIP = '';
            }
        }
    }
    
    my $syncserver = $ConfigSync{$name}->{sync_server};
    my ($k,$v,$ns);
    $ns = 0;
    while ( ($k,$v) = each %{$syncserver}) {$ns++ if $isShareMaster && ($v == 1 or $v == 2 or $v == 4);}
    while ( ($k,$v) = each %{$syncserver}) {
        my $isM = $isShareMaster && ($v == 1 or $v == 2 or $v == 4);
        my $s = $k;
        $s =~ s/\:\d+$//o;
        if ($s eq $ip && $isM) {
            $syncserver->{$k} = ($ns == 1) ? 2 : 4;
        } elsif ($isM) {
            $syncserver->{$k} = 1;
        } else {
            $syncserver->{$k} = 3;
        }
    }

    unlink $file;
}
