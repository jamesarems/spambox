#line 1 "sub main::maillogFilename"
package main; sub maillogFilename {
    my ($fh,$isspam)  = @_;
    d('maillogFilename '.$isspam);
    return if ! $fh;
    my $this=$Con{$fh};
    my $oisspam;
    $oisspam = " - internal($isspam)" if $SessionLog > 2;
    $isspam -= 2;
    my @dirs    = (  'notspamlog', 'spamlog', 'incomingOkMail', 'viruslog', 'discarded', 'discarded' );
    my $maillog = ${$dirs[$isspam]};
    if (! $maillog) {
        mlog(0,"info: no logging folder found for $dirs[$isspam]$oisspam") if $SessionLog > 1;
        return;
    }
    my $sub; my $sub2;
    if (! $this->{subject} || $UseSubjectsAsMaillogNames) {
        if ($this->{subject2}) {
            $sub = $this->{subject2};
        } else {
            $sub = $1 if (substr($this->{header},0,index($this->{header},"\015\012\015\012")) =~ /\015\012Subject: *($HeaderValueRe)/iso);
            if (!$sub && $this->{maillogbuf}) {
                $sub = $1 if (substr($this->{maillogbuf},0,index($this->{maillogbuf},"\015\012\015\012")) =~ /\015\012Subject: *($HeaderValueRe)/iso);
            }
        }
        $sub =~ s/\r\n\s*//go;

        $sub =~ s/\r?\n$//o;
        $sub =~ s/$NONPRINT//go;
        $sub = decodeMimeWords2UTF8($sub);

        $sub2 = $sub;
        $sub = d8($sub);
        $sub =~ s/[^a-zA-Z0-9]/_/go if (! ($UseUnicode4MaillogNames && $canUnicode));
        $sub =~ s/^\P{IsAlnum}+/_/go;
        $sub =~ s/[\^\s\<\>\?\"\'\:\|\\\/\*\&\.]|\p{Currency_Symbol}/_/igo;  # remove not allowed characters and spaces from file name
        $sub =~s/\.{2,}/./go;
        $sub =~s/_{2,}/_/go;
        $sub =~s/[_\.]+$//o;
        $sub =~s/^[_\.]+//o;
        if (! $this->{subject}) {
            $this->{subject} = substr( $sub, 0, 50 );
            $this->{subject} = e8($this->{subject});
        }
        $sub = substr($sub,0,($MaxFileNameLength ? $MaxFileNameLength : 50))
            if($UseSubjectsAsMaillogNames);
        $sub = e8($sub);
    }

    my $Counter = $this->{hasmallogname};
    if (! $this->{hasmallogname}) {
        lock(%Stats) if (is_shared(%Stats));
        lock($lockSpamfileNames) if is_shared($lockSpamfileNames) && ! is_shared(%Stats);
        if (($Counter = ++$Stats{Counter}) > 999999999) {
            threads->yield();
            $Counter = $Stats{Counter} = 1;
        }
        threads->yield();
    }
    
    if ( $UseSubjectsAsMaillogNames
         && $sub
         && $discarded
         && $isspam == 1
         && $MaxAllowedDups
         && ! $this->{hasmallogname}
         && ! $RunTaskNow{'fillSpamfiles'}
         && $sub2 !~ /$AllowedDupSubjectReRE/)
    {
          my $md5sub = Digest::MD5::md5($sub) ;
          lock($lockSpamfileNames) if is_shared($lockSpamfileNames);
          threads->yield();
          if ($Spamfiles{$md5sub} >= $MaxAllowedDups) {
              my @nums = sort {$main::a <=> $main::b} split(/\s+/o, $SpamfileNames{$md5sub});
              my $num = shift @nums;
              push @nums , $Counter;
              $SpamfileNames{$md5sub} = join(' ',@nums);
              my $source = "$base/$spamlog/$sub--$num$maillogExt";
              my $target = "$base/$discarded/$sub--$num$maillogExt";
              mlog($fh,"MaxAllowedDups reached for this subject - moved oldest file $source to $target")
                  if $move->($source,$target) && $SessionLog;
          } else {
              $SpamfileNames{$md5sub} .= ' ' if $Spamfiles{$md5sub}++;
              $SpamfileNames{$md5sub} .= $Counter;
          }
          threads->yield();
    }

    $this->{hasmallogname} = $Counter;
    if ( $UseSubjectsAsMaillogNames || $isspam == 2 || $isspam == 3 ) {
        $sub .= "--" . $Counter;
    } elsif ( ! $UseSubjectsAsMaillogNames
             && $MaintBayesCollection
             && (   $MaxBayesFileAge && $isspam < 2
                 || $MaxNoBayesFileAge && $isspam > 1)
            )
    {
        $sub = $this->{mfn} . "--" . $Counter ;
    } else {
        $sub = $this->{mfn};
    }
    my $ret = "$base/$maillog/$sub$maillogExt";
    return $ret;
}
