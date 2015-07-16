#line 1 "sub main::skipevery"
package main; sub skipevery {
    d('skipevery');
    my ($fh,$l)=@_;
    $Con{$fh}->{getline}=$Con{$fh}->{Xgetline} if $Con{$fh}->{Xgetline};
    $Con{$fh}->{Xgetline}->($fh,$Con{$fh}->{Xreply}) if $Con{$fh}->{Xgetline} && $Con{$fh}->{Xreply};
    delete $Con{$fh}->{Xgetline};
}
