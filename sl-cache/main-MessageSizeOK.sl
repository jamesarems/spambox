#line 1 "sub main::MessageSizeOK"
package main; sub MessageSizeOK {
    my $fh = shift;
    my $this=$Con{$fh};
    d('MessageSizeOK');

    my $maxRealSize = $maxRealSize || 0;
    $maxRealSize = $this->{maxRealSize} if defined $this->{maxRealSize};
    my $maxSize = $maxSize || 0;
    $maxSize = $this->{maxSize} if defined $this->{maxSize};
    if ($this->{relayok} && ! defined $this->{maxSize}) {
        $this->{maxRealSize} = $this->{maxSize} = 0;
        my @MSadr  = sort {$main::b <=> $main::a} map {&matchHashKey('MSadr' ,$_)} split(/\s+/o,$this->{rcpt}),$this->{mailfrom},$this->{ip},$this->{cip},@{$this->{sip}};
        my @MRSadr = sort {$main::b <=> $main::a} map {&matchHashKey('MRSadr',$_)} split(/\s+/o,$this->{rcpt}),$this->{mailfrom},$this->{ip},$this->{cip},@{$this->{sip}};
        $maxSize = $this->{maxSize} = $MSadr[0] if (defined $MSadr[0]);
        $maxSize = $this->{maxSize} = 0 if grep({$_ == 0} @MSadr);
        $maxRealSize = $this->{maxRealSize} = $MRSadr[0] if (defined $MRSadr[0]);
        $maxRealSize = $this->{maxRealSize} = 0 if grep({$_ == 0} @MRSadr);
    }
    
    my $maxRealSizeExternal = $maxRealSizeExternal || 0;
    $maxRealSizeExternal = $this->{maxRealSizeExternal} if defined $this->{maxRealSizeExternal};
    my $maxSizeExternal = $maxSizeExternal || 0;
    $maxSizeExternal = $this->{maxSizeExternal} if defined $this->{maxSizeExternal};
    if (! $this->{relayok} && ! defined $this->{maxSizeExternal}) {
        $this->{maxRealSizeExternal} = $this->{maxSizeExternal} = 0;
        my @MSEadr  = sort {$main::b <=> $main::a} map {&matchHashKey('MSEadr' ,$_)} split(/\s+/o,$this->{rcpt}),$this->{mailfrom},$this->{ip},$this->{cip},@{$this->{sip}};
        my @MRSEadr = sort {$main::b <=> $main::a} map {&matchHashKey('MRSEadr',$_)} split(/\s+/o,$this->{rcpt}),$this->{mailfrom},$this->{ip},$this->{cip},@{$this->{sip}};
        $maxSizeExternal = $this->{maxSizeExternal} = $MSEadr[0] if (defined $MSEadr[0]);
        $maxSizeExternal = $this->{maxSizeExternal} = 0 if grep({$_ == 0} @MSEadr);
        $maxRealSizeExternal = $this->{maxRealSizeExternal} = $MRSEadr[0] if (defined $MRSEadr[0]);
        $maxRealSizeExternal = $this->{maxRealSizeExternal} = 0 if grep({$_ == 0} @MRSEadr);
    }

    if ( ($this->{relayok} && $maxRealSize
            && ( ($this->{SIZE} > $this->{maillength} ? $this->{SIZE} : $this->{maillength}) * $this->{numrcpt} > $maxRealSize )) ||
         (!$this->{relayok} && $maxRealSizeExternal
            && ( ($this->{SIZE} > $this->{maillength} ? $this->{SIZE} : $this->{maillength}) * $this->{numrcpt} > $maxRealSizeExternal ))
       )
    {
        &makeSubject($fh);
        my $max = $this->{relayok} ? $maxRealSize : $maxRealSizeExternal;
        my $err = "552 message exceeds MAXREALSIZE byte (size \* rcpt)";
        if ($this->{relayok}) {
            mlog( $fh, "warning: message exceeds maxRealSize $max bytes (size \* rcpt)!" );
        } else {
            $this->{prepend} = 'MaxRealMessageSize';
            my $fn = $this->{maillogfilename};
            $fn=' -> '.$fn if $fn ne '';
            $fn='' if !$fileLogging;
            my $logsub = ( $subjectLogging && $this->{originalsubject} ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
            mlog( $fh, "[spam found] (message exceeds maxRealSize $max bytes (size \* rcpt)!)$logsub".de8($fn).';',0,2 );
            $this->{prepend} = '';
        }
        $err = $maxRealSizeError if ($maxRealSizeError);
        $err =~ s/MAXREALSIZE/$max/go;
        seterror( $fh, $err, 1 );
        return 0;
    }

    if ( (  $this->{relayok} && $maxSize         && $this->{maillength} > $maxSize         ) ||
         (! $this->{relayok} && $maxSizeExternal && $this->{maillength} > $maxSizeExternal )
       )
    {
        &makeSubject($fh);
        my $max = $this->{relayok} ? $maxSize : $maxSizeExternal;
        my $err = "552 message exceeds MAXSIZE byte (size)";
        if ($this->{relayok}) {
            mlog( $fh, "warning: message exceeds maxSize $max bytes (size)!" );
        } else {
            $this->{prepend} = 'MaxMessageSize';
            my $fn = $this->{maillogfilename};
            $fn=' -> '.$fn if $fn ne '';
            $fn='' if !$fileLogging;
            my $logsub = ( $subjectLogging && $this->{originalsubject} ? " $subjectStart$this->{originalsubject}$subjectEnd" : '' );
            mlog( $fh, "[spam found] (message exceeds maxSize $max bytes (size)!)$logsub".de8($fn).';',0,2 );
            $this->{prepend} = '';
        }
        $err = $maxSizeError if ($maxSizeError);
        $err =~ s/MAXSIZE/$max/go;
        seterror( $fh, $err, 1 );
        return 0;
    }
    return 1;
}
