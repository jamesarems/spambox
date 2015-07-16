#line 1 "sub main::allRot"
package main; sub allRot {
    my $ad = shift;
    $ad =~ tr/A-Za-z/N-ZA-Mn-za-m/;
    return ($ad);
}
