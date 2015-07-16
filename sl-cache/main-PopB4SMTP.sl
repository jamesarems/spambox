#line 1 "sub main::PopB4SMTP"
package main; sub PopB4SMTP {
    my $ip=shift;
    if($PopB4SMTPMerak) {
        return 1 if PopB4Merak($ip);
        return 0;
    }
    return 0 unless $PopB4SMTPFile;

    my %hash;

    eval {
    # tie %hash, 'DB_File', $PopB4SMTPFile, O_READ, 0400, $DB_HASH;
    tie %hash, 'DB_File', $PopB4SMTPFile;
    if($hash{$ip}) {
        mlog(0,"PopB4SMTP OK for $ip");
        return 1;
    } else {
        mlog(0,"PopB4SMTP failed for $ip");
        return 0;
    }
    };
}
