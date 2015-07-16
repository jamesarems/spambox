#line 1 "sub main::webBlock"
package main; sub webBlock {
    my $tempfh = shift;
    print $tempfh &webBlockText();
    return 1;
}
