#line 1 "sub main::MSGIDsigRemove"
package main; sub MSGIDsigRemove {
    my $fh = shift;
    d('MSGIDsigRemove');
    my $this = $Con{$fh};
    my $removed;
    my $old;
    
    return if $this->{MSGIDsigRemoved};
    my $headlen = $this->{headerlength} || getheaderLength($fh);  # do only the header
    $this->{headerlength} = $headlen;
    my $maxlen = $MaxBytes && $MaxBytes < $this->{maillength} ? $MaxBytes : $this->{maillength};
    $headlen = $maxlen if ($maxlen > $headlen && $this->{isbounce});      # do complete mail if bounce
    my $alltodo = substr($this->{header},0,$headlen);
    my $todo = $alltodo;
    my $found = 0;
    do {
        if ($todo =~ /((?:[^\r\n]+\:)[\r\n\s]*)?\<$MSGIDpreTag\.(\d)(\d\d\d)(\w{6})\.([^\r\n]+)\>/) {
            my ($line, $gen, $day, $hash, $orig_msgid) = ($1,$2,$3,$4,$5);
            $found = 1;
            my $secret;
            for (@msgid_secrets) {
                if ($_->{gen} == $gen) {
                    $secret = $_->{secret};
                    last;
                }
            }
            if ($secret) {
                my $hash_source =  $gen . $day . $orig_msgid;
                my $hash2 = substr(sha1_hex($hash_source . $secret), 0, 6);
                if ($hash eq $hash2) {
                    $old = $MSGIDpreTag.'.'.$gen.$day.$hash.'.';
                    $alltodo =~ s/\Q$old\E//;
                    $removed = 1;
                    $this->{nodkim} = 1;
                    $line =~ s/[\r\n\s]*//og;
                    mlog($fh,"info: removed MSGID-signature from [$line]") if ($line && $MSGIDsigLog >= 2);
                }
            }
            $old = $MSGIDpreTag.'.'.$gen.$day.$hash.'.'.$orig_msgid;
            my $pos = index($todo, $old) + length($old);
            $todo = substr($todo,$pos,length($todo) - $pos);
        } else {
            $found = 0;
        }
    } while ($found);
    if ($removed) {
        substr($this->{header},0,$headlen,$alltodo);
    }
    my $txt = $this->{isbounce} ? 'and body in bounced message' : '';
    mlog($fh, "info: removed MSGID-signature from header $txt") if ($MSGIDsigLog && $removed);
    $this->{MSGIDsigRemoved} = 1 if (! $this->{isbounce} || ($MaxBytes && $MaxBytes < $this->{maillength})); # in bounces we have to process the body
    return;
}
