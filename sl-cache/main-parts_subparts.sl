#line 1 "sub main::parts_subparts"
package main; sub parts_subparts {
    my $email = shift;
    return unless ref($email);
    my @parts;
    eval {
        foreach my $part ($email->parts) {
           if ($part->parts > 1) {
               eval{$part->walk_parts(sub {push @parts, @_;})};
               push @parts,$part if $@;
           } else {
               push @parts,$part;
           }
        }
    };
    return @parts;
}
