#line 1 "sub main::allocateMemory"
package main; sub allocateMemory {
    my $fh = shift;
    return unless eval {require Convert::Scalar;};
    d('allocateMemory');
    my $this = $Con{$fh};
    my $friend = $Con{$this->{friend}};
    my $temp;
    my $sizein = $PreAllocMem ? $PreAllocMem : 100000;
    my $sizeout;

    $sizein = $this->{SIZE} + 4096 if ($this->{SIZE});
    return if ($sizein <= $friend->{allocmem} * 1048576);
    $sizeout = $sizein;
    $sizeout = $npSizeOut + 4096 if ($npSizeOut && $npSizeOut < $sizeout);

    my $mlbufsize = max(($MaxBytes ? $MaxBytes + 1024 : 0),
                        ($StoreCompleteMail >= $sizein ? $sizein : 0),
                        ($StoreCompleteMail < $sizein ? $StoreCompleteMail : 0)
                       );
#    mlog(0,"info: allocate memory: header=$sizein , maillogbuf=$mlbufsize , outgoing=$sizeout");
    d("allocate memory: header=$sizein , maillogbuf=$mlbufsize , outgoing=$sizeout");
    grow(\$this->{header} ,$sizein);
    grow(\$this->{maillogbuf} , $mlbufsize) if  ! $NoMaillog;
    grow(\$friend->{outgoing} , $sizeout) if $friend;
    if ($ConTimeOutDebug) {
        grow(\$this->{contimeoutdebug} , int($sizein * 1.5));
    }
}
