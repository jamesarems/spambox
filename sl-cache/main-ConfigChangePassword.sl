#line 1 "sub main::ConfigChangePassword"
package main; sub ConfigChangePassword {my ($name, $old, $new, $init)=@_;

    # change the Password
    if (!$init) {
        if ($new) {
            $Config{webAdminPassword}=$webAdminPassword=$new;
            $Config{webAdminPassword}=$webAdminPassword=crypt($webAdminPassword,"45") if ($new !~ /^45/o || length($new) != 13);
            mlog(0,"AdminUpdate: root Password changed");
        } elsif (! $new && ! $old) {
            $new = $old = $webAdminPassword;
        } else {
            mlog(0,"error: ConfigChangePassword called without defining a value");
            return;
        }
        my $dec = ASSP::CRYPT->new($old,0);
        my $enc = ($usedCrypt == -1) ? ASSP::CRYPT->new($webAdminPassword,0,1) : ASSP::CRYPT->new($webAdminPassword,0);
        foreach my $file (keys %CryptFile) {
            (open my $cf,'<' ,"$file") or next;
            binmode $cf;
            my $content = join('',<$cf>);
            close $cf;
            $content = $enc->ENCRYPT($dec->DECRYPT($content));
            (open $cf, '>',"$file") or next;
            binmode $cf;
            print $cf $content;
            close $cf;
        }
        while (my ($k,$v) = each(%webAuthStore)) {
            $v->[1] = $enc->ENCRYPT($dec->DECRYPT($v->[1]));
        }
        if ($usedCrypt == -1) {
            ConfigChangePassPhrase('adminusersdbpass', $Config{adminusersdbpass}, $Config{adminusersdbpass}, 0);
            $usedCrypt = 1 ;
            mlog(0,"AdminUpdate: the used encryption engine is now changed to use the very fast 'Crypt::GOST' module");
        }
        return '';
    }
}
