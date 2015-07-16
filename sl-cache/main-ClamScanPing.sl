#line 1 "sub main::ClamScanPing"
package main; sub ClamScanPing {
 my $self = shift;
 my $response;
 my $timeout = $ClamAVtimeout / 2;
 $timeout = 2 if $timeout < 2;
 d('ClamScanPing - maxwait ' . $timeout * 2 . ' seconds');

 my $conn = $self->_get_connection || return;
 my $select = IO::Select->new();
 $select->add($conn);

 my @canwrite = $select->can_write(int($timeout));
 if (@canwrite) {
     $self->_send($conn, "PING\n");

     my @canread = $select->can_read(int($timeout) || 1);

     if (@canread) {
         chomp($response = $conn->getline);

     # Run out the buffer?
         1 while (<$conn>);
     } else {
         $response = 'unable to read from Socket';
     }
 } else {
     $response = 'unable to write to Socket';
 }
 $select->remove($conn);
 $conn->close;

 return ($response eq 'PONG' ? 1 : $self->_seterrstr("Unknown reponse from ClamAV service: $response"));
}
