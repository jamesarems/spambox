#line 1 "sub main::ClamScanScan"
package main; sub ClamScanScan {
 my ($self) = shift;
 my $response;
 my $timeout = $ClamAVtimeout / 2;
 $timeout = 2 if $timeout < 2;
 d('ClamScanScan - maxwait ' . ($timeout + $ClamAVtimeout) . ' seconds');

 my $data = join '', @_;

 $self->_seterrstr;

 my $conn = $self->_get_connection || return;
 my $select = IO::Select->new();
 $select->add($conn);

 my @canwrite = $select->can_write(int($timeout));
 if (@canwrite) {
     $self->_send($conn, "STREAM\n");
     chomp($response = $conn->getline);
 }
 
 my @return;
 if($response =~ /^PORT (\d+)/o){
	if((my $c = $self->_get_tcp_connection($1))){
        my $stream = IO::Select->new();
        $stream->add($c);
        my $st = Time::HiRes::time();
        my @cwrite = $stream->can_write(int($timeout));
        $main::ThreadIdleTime{$main::WorkerNumber} += Time::HiRes::time() - $st;
        if (@cwrite) {
            $self->_send($c, $data);
            $stream->remove($c);
            $c->close;
            my $st = Time::HiRes::time();
            my @canread = $select->can_read(int($ClamAVtimeout) || 1);
            $main::ThreadIdleTime{$main::WorkerNumber} += Time::HiRes::time() - $st;
            if (@canread) {
		        chomp(my $r = $conn->getline);
		        if($r =~ /stream: (.+) FOUND/io){
    		   	    @return = ('FOUND', $1);
		        } else {
    			    @return = ('OK');
		        }
            }
        }
	} else {
        $select->remove($conn);
        $conn->close;
        return;
	}
 }
 $select->remove($conn);
 $conn->close;
 return @return;
}
