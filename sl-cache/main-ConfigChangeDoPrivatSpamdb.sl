#line 1 "sub main::ConfigChangeDoPrivatSpamdb"
package main; sub ConfigChangeDoPrivatSpamdb {
    my ($name, $old, $new, $init)=@_;
    return if $WorkerNumber != 0;
    if ($new && $Config{spamdb} !~ /DB:/o) {
        $qs{$name} = ${$name} = $Config{$name} = 0;
        mlog(0,"error: unable to set $name to $new - spamdb is not set to 'DB:'");
        return "<br />*** unable to set $name to $new - spamdb is not set to 'DB:' ***<script type=\"text/javascript\">alert(\'unable to set $name to $new - set spamdb to DB: first!\');</script>";
    }
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'") unless ($init || $new eq $old);
    ${$name} = $Config{$name} = $new;
    return '';
}
