#line 1 "sub main::AttachMD5Mail"
package main; sub AttachMD5Mail {
    my $m = shift;
    my $msg = ref($m) ? $m : \$m;
    return unless $$msg;
    return unless eval('$main::ASSP_AFCDetectSpamAttachRe');
    my %md5;
    my $t = Time::HiRes::time() + 3;

    $o_EMM_pm = 1;
    eval {
        $Email::MIME::ContentType::STRICT_PARAMS=0;      # no output about invalid CT
        my $re = ${'main::ASSP_AFCDetectSpamAttachReRE'};
        my $email = Email::MIME->new($$msg);
        fixUpMIMEHeader($email);

        if (Time::HiRes::time() > $t) {
            $t = sprintf("%.2f",(Time::HiRes::time() - $t + 3));
            mlog(0,"info: break attachment MD5 processing after $t seconds - parsing MIME took too long");
            return \%md5;
        }

        my $i = 0;
        my @parts = parts_subparts($email);
        foreach my $part ( @parts ) {
            if (Time::HiRes::time() > $t) {
                $t = sprintf("%.2f",(Time::HiRes::time() - $t + 3));
                mlog(0,"info: break attachment MD5 processing after $t seconds - processed $i MIME parts");
                last;
            }
            ++$i;
            next if $part->header("Content-Type") !~ /$re/io;
            my $MD5Part = AttachMD5Part($part);
            $md5{$MD5Part}++ if $MD5Part;
        }
    };
    $o_EMM_pm = 0;
    return \%md5;
}
