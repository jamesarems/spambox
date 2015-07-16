#line 1 "sub main::syncRCVQuit"
package main; sub syncRCVQuit {
    my($fh,$l)=@_;
    d('syncRCVQuit');
    my $this=$Con{$fh};
    if($l=~/^QUIT/io) {
        $this->{lastcmd} = 'QUIT';
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        my $time = sprintf("%.3f",(Time::HiRes::time()));
        my $var; $var = $1 if $this->{header} =~ s/^([^\r\n]+)\r\n//os;
        &NoLoopSyswrite($fh,"221 <$myName> closing transmission for SYNC $var\r\n",0);
        unless (defined ${$var}) {
            mlog(0,"warning: $var is no valid Configuration Parameter - ignore request");
            done($fh);
            return;
        }
        -d "$base/configSync/" or mkdir "$base/configSync", 0755;
        my $file = "$base/configSync/" . $var . '.' . $time  . '.' . $this->{syncServer} . '.cfg';
        if (open my $FH, '>',"$file") {
            binmode $FH;
            $this->{header} =~ s/\.[\r\n]+$//o;
            print $FH ASSP::CRYPT->new($webAdminPassword,0)->ENCRYPT($this->{header});
            close $FH;
            $syncToDo = 1;
        } else {
            mlog(0,"syncCFG: error - unable to write file $file - $!");
        }
    } else {
        ($this->{lastcmd}) = $l =~ /^\s*(\S+)[\s\r\n]+/o;
        push(@{$this->{cmdlist}},$this->{lastcmd}) if $ConnectionLog >= 2;
        mlog($fh,"syncCFG: error - syncRCVQuit expected 'QUIT' got $l");
        NoLoopSyswrite($fh,"500 sequence error after DATA - Quit expected\r\n",0);
    }
    done($fh);
}
