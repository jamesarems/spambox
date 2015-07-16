#line 1 "sub main::syncRCVData2"
package main; sub syncRCVData2 {
    my($fh,$l)=@_;
    d('syncRCVData2');
    my $this=$Con{$fh};
    $this->{header} .= $l;
    if($this->{header} =~ /\r\n\.\r\n$/os) {
        $Con{$fh}->{getline}=\&syncRCVQuit;
        sendque($fh,"250 OK got all SYNC data\r\n");
    }
}
