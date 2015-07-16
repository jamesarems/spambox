#line 1 "sub main::configUpdateGlobalClient"
package main; sub configUpdateGlobalClient {
    my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: global-PB-clientname updated from '$old' to '$new'") unless $init || $new eq $old;
    $new =~ s/\'\"//go;
    if ($new eq '') {
        $globalClientPass = '';
        $Config{globalClientPass}='';
        $globalClientLicDate = '';
        $Config{globalClientLicDate}='';
        return ' global penalty box upload/download is now disabled';
    } elsif ($new =~ /^\s*(?:clean(?:up)?|del(?:ete)?|rem(?:ove)?|clear)\s*$/io) {
        $Config{$name} = ${$name} = '';
        delete $Config{globalRegisterURL};
        delete $Config{globalUploadURL};
        delete $ConfigAdd{globalRegisterURL};
        delete $ConfigAdd{globalUploadURL};
        $globalRegisterURL = undef;
        $globalUploadURL = undef;
        $globalClientPass = '';
        $Config{globalClientPass}='';
        $globalClientLicDate = '';
        $Config{globalClientLicDate}='';
        my $C = $C->();
        $C =~ s/([0-9a-fA-F]{2})/pack('C',hex($1))/geo; eval($C);
        $globalRegisterURL = $ConfigAdd{globalRegisterURL} = $Config{globalRegisterURL};
        $globalUploadURL = $ConfigAdd{globalUploadURL} = $Config{globalUploadURL};
        &SaveConfig();
        return ' global penalty box configuration was cleaned up';
    } else {
       my $res = &registerGlobalClient($new);
       if ($res == 1) {
          return " clientname $new was successful registered on global-PB server";
       } else {
          $globalClientPass = '';
          $globalClientName = '';
          $Config{globalClientPass}='';
          $Config{$name}='';
          $globalClientLicDate = '';
          $Config{globalClientLicDate}='';
          &SaveConfig();
          mlog(0,"warning: registration for clientname $new global-PB server failed : $res");
          return
          '<span class="negative">*** registration for clientname '.$new.' on global-PB server failed : '.$res.'</span><script type=\"text/javascript\">alert(\'global-client registration failed - '.$res.'\');</script>';
       }
    }
}
