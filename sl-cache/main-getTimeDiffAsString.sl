#line 1 "sub main::getTimeDiffAsString"
package main; sub getTimeDiffAsString {

	my ($tdiff,$seconds) = @_;

	my $days  = int( $tdiff / 86400 );
	my $hours = int( ( $tdiff - ( $days * 86400 ) ) / 3600 );
	my $mins  = int( ( $tdiff - ( $days * 86400 ) - ( $hours * 3600 ) ) / 60 );
	my $secs  = int( $tdiff - ( $days * 86400 ) - ( $hours * 3600 ) - ( $mins * 60 ) );

	my $ret;
	$ret = $days . " day" . ( $days == 1 ? ' ' : "s " );
	$ret .= $hours . " hour" . ( $hours == 1 ? ' ' : "s " );
	$ret .= $mins . " min" .   ( $mins == 1  ? ' ' : "s " );
	$ret .= $secs . " sec" .   ( $secs == 1  ? ' ' : "s " ) if $seconds;

	return $ret;
}
