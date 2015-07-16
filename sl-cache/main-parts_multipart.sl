#line 1 "sub main::parts_multipart"
package main; sub parts_multipart {
    my $self = shift;

    #use the original code, if don't need the hack
    return $org_Email_MIME_parts_multipart->($self) if $o_EMM_pm;

    my $boundary = $self->{ct}->{attributes}->{boundary};

    return $self->parts_single_part
        unless $boundary and $self->body_raw =~ /^--\Q$boundary\E\s*$/sm;

    $self->{body_raw} ||= $self->body_raw;

    # rfc1521 7.2.1
    my ($body, $epilogue) = split /^--\Q$boundary\E--\s*$/sm, $self->body_raw, 2;

    my @bits = split /^--[^\n\r]+\s*$/smo, ($body || '');

    $self->{body} = undef;
    $self->{body} = (\shift @bits) if ($bits[0] || '') !~ /:/o;

    my $bits = @bits;

    my @parts;
    for my $bit (@bits) {
        $bit =~ s/\A[\n\r]+//smgo;
#        $bit =~ s/(?<!\x0d)$self->{mycrlf}\Z//smg;
        my $email = (ref $self)->new($bit);
        push @parts, $email;
    }

    $self->{parts} = \@parts;

    return @{ $self->{parts} };
}
