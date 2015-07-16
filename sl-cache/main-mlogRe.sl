#line 1 "sub main::mlogRe"
package main; sub mlogRe{
	my($fh,$subre,$regextype,$check)=@_;
	my $this = exists $Con{$fh} ? $Con{$fh} : {};
	$subre =~ s/\s+/ /go;
	$subre=substr($subre,0,$RegExLength);
	$this->{messagereason}="Regex: $regextype '$subre'";
 	$this->{myheader}.="X-Assp-Re-$regextype: $subre\r\n" if $AddRegexHeader;
    my $m;
	$m = $check . ' ' if $check;
	$m .= $this->{messagereason};
	mlog( $fh, $m, 1, 1 ) if $regexLogging;
}
