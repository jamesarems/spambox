#line 1 "sub main::addMyheader"
package main; sub addMyheader {
    my $fh = shift;
    my $this = $Con{$fh};
    d('addMyheader');
    my $var = $this->{addMyheaderTo} || 'header';
    return unless $this->{myheader};

    my $foundEnd = my $headlen = index($this->{$var}, "\x0D\x0A\x0D\x0A");  # merge header
    $headlen = 0 if ($headlen < 0);
    my $preheader = my $header = substr($this->{$var},0,$headlen);
    if ($this->{preheaderlength}) {    # we have added our headers before - now find the end of the orig header
        $this->{preheaderlength} -= 2; # step back two bytes  ("\x0D\x0A")
        $this->{preheaderlength} = 0 if $this->{preheaderlength} < 0;   # min offset is 0
        $this->{preheaderlength} = index($this->{$var}, "\x0D\x0A",$this->{preheaderlength});
        $this->{preheaderlength} = ( $this->{preheaderlength} < 0 ) ? 0 : $this->{preheaderlength} + 2;
        $preheader = substr($header,0,$this->{preheaderlength});
    }
    my $myheader = headerFormat($this->{myheader});
    $myheader =~ s/(?:\r|\n)+$//o;
    $myheader .= "\r\n" if $myheader;
    $preheader =~ s/(?:\r|\n)+$//o;
    $preheader .= "\r\n" if $preheader;
    $this->{preheaderlength} = length $preheader;
    my $newheader = $preheader . $myheader;
    if ($foundEnd >= 0) {
       $newheader =~ s/(?:\r|\n)+$//o;
    } elsif ($newheader) {
       $newheader .= "\r\n\r\n";
    }

    substr($this->{$var},0,$headlen,$newheader);
    $this->{maillength} = length($this->{$var});
}
