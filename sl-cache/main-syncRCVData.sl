#line 1 "sub main::syncRCVData"
package main; sub syncRCVData {
    my($fh,$l)=@_;
    d('syncRCVData');
    my $this=$Con{$fh};
    if($l=~/^DATA/io) {
        $this->{lastcmd} = 'DATA';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        $Con{$fh}->{getline}=\&syncRCVData2;
        sendque($fh,"354 send data\r\n");
    } else {
        ($this->{lastcmd}) = $l =~ /^\s*(\S+)[\s\r\n]+/o;
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        mlog($fh,"syncCFG: error - syncRCVData expected 'DATA' got $l");
        NoLoopSyswrite($fh,"500 sequence error - DATA expected\r\n",0);
        done($fh);
    }
}
