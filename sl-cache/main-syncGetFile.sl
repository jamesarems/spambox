#line 1 "sub main::syncGetFile"
package main; sub syncGetFile {
    d('syncGetFile');
    my $file = shift;
    my $ffil = $file;
    $ffil="$base/$ffil" if $ffil!~/^\Q$base\E/o;
    if ($FileNoSync{$ffil}) {
        mlog(0,"syncCFG: '# assp-no-sync' defined - synchronization ignored for file $base/$ffil");
        return;
    }
    my $body;
    
    if (open my $FH, '<',$ffil) {
        binmode $FH;
        my $cont = join('',<$FH>);
        close $FH;
        if (exists $CryptFile{$ffil} && $cont =~ /^(?:[a-zA-Z0-9]{2})+$/o) {
            my $enc = ASSP::CRYPT->new($webAdminPassword,0);
            $cont = $enc->DECRYPT($cont);
        }
        $body  = MIME::Base64::encode_base64("# file start $file\r\n",'')."\r\n";
        $body .= MIME::Base64::encode_base64($cont,'') . "\r\n";
        $body .= MIME::Base64::encode_base64("# file eof\r\n",'')."\r\n";
    }
    return $body;
}
