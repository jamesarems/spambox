#line 1 "sub main::unformatTimeInterval"
package main; sub unformatTimeInterval {
    my ($interval,$default)=@_;
    my @a=split(/\s+/o,$interval);
    my $res=0;
    while (@a) {
        my $j = shift @a;
        my ($i,$mult)=$j=~/^(.*?) ?([smhd]?)$/o;
        $mult||=$default||'s'; # default to seconds
        if ($mult eq 's') {
            $res+=$i;
        } elsif ($mult eq 'm') {
            $res+=$i*60;
        } elsif ($mult eq 'h') {
            $res+=$i*3600;
        } elsif ($mult eq 'd') {
            $res+=$i*86400;
        }
    }
    return $res;
}
