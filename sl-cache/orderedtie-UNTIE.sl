#line 1 "sub orderedtie::UNTIE"
package orderedtie; sub UNTIE {
    my ($self,$count) = @_;
    return unless ref $self;
    eval{$self->flush();};
    &main::mlog(0, "error: untie attempted in orderedtie for $self->{fn} while $count inner references still exist") if $count;
}
