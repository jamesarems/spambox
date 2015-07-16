#line 1 "sub main::existFile"
package main; sub existFile {
    my $file = shift;
    return 0 unless $file;
    return ($eF->( $file ) or -e $file);
}
