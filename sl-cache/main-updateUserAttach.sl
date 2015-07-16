#line 1 "sub main::updateUserAttach"
package main; sub updateUserAttach {my ($name, $old, $new, $init)=@_;
    mlog(0,"AdminUpdate: user based attachments updated from '$old' to '$new'") unless $init || $new eq $old;
    ${$name} = $Config{$name} = $new unless $WorkerNumber;
    my @new = checkOptionList($new,$name,$init);
    if ($new[0] =~ s/^\x00\xff //o) {
        ${$name} = $Config{$name} = $old;
        return ConfigShowError(1,$new[0]);
    }
    my $oldcount = keys %AttachRules;
    %AttachRules = ();
    %AttachZipRules = ();
    my $c = sub {my $e = shift;$e =~ s/^['" ]//o;$e =~ s/['" ]$//o;return(defined ${chr(ord("\026") << 2)})?$e:undef;};
    my $ret;
    while (@new) {
        my $zip;
        my $line = lc(shift @new);
        $line =~ s/^\s+//o;
        $line =~ s/[\s\r\n]+$//o;
        next unless $line;
        my @entry = split(/\s*(?:[=-]\>|[,;])\s*|\s+/o,$line);
        (my $user = shift @entry) or next;
        my $desc = "$name - $user";
        ($zip,$user) = split(/\:/o , $user) if $user =~ /\:/o;
        if ($zip && lc($zip) ne 'zip') {
            $ret .= ConfigShowError(0,"warning: found unknown user based attachments starting tag '$zip' for user '$user' - entry is ignored");
            next;
        }
        $ret .= &ConfigRegisterGroupWatch(\$user,$name,$desc);
        foreach my $u (split(/\|/,$user)) {
            my @e = @entry;
            while (@e) {
                my $what = $c->(shift @e);
                my $re = $c->(shift @e);
                next if (! ($re && $what));
                $AttachRules{$u}->{$what} = $re unless $zip;
                $AttachZipRules{$u}->{$what} = $re if $zip;
                $re = ($AttachmentLog < 2) ? '' : ' = '.$re;
                mlog(0,"info: user based attachment check set: $u -> $what$re") if $AttachmentLog && $WorkerNumber == 0 && ! $zip;
                mlog(0,"info: user based compressed attachment check set: $u -> $what$re") if $AttachmentLog && $WorkerNumber == 0 && $zip;
            }
        }
    }
    my $newcount = keys %AttachRules;
    mlog(0,"info: all user based attachment checks are removed") if $AttachmentLog && $WorkerNumber == 0 && $oldcount && ! $newcount;
    return $ret;
}
