#line 1 "sub main::Glob"
package main; sub Glob {
    my @g;
    if ($] !~ /^5\.016/o) {
        @g = glob("@_");
    } else {
        map {push @g , < $_ >;} @_ ;
    }
    return @g;
}
