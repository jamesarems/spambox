#line 1 "sub main::MaillogRemove"
package main; sub MaillogRemove {
    my $this = shift;
    d('MaillogRemove');
    return 0 unless $this;
    if ($this->{maillogfilename} && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?(?:$notspamlog|$incomingOkMail)/) {
        if (($notspamlog && $discarded && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?(?:$notspamlog|$discarded)/) or
          (! $notspamlog && $discarded && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?$discarded/) or
          ($notspamlog && ! $discarded && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?$notspamlog/))
        {
            mlog($this->{self},"info: logfile ".de8($this->{maillogfilename})." not removed (reason 1)") if $SessionLog > 1;
            return 0;
        }
        if (($incomingOkMail && $discarded && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?(?:$incomingOkMail|$discarded)/) or
          (! $incomingOkMail && $discarded && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?$discarded/) or
          ($incomingOkMail && ! $discarded && $this->{maillogfilename} !~ /^(?:\Q$base\E\/)?$incomingOkMail/))
        {
            mlog($this->{self},"info: logfile ".de8($this->{maillogfilename})." not removed (reason 2)") if $SessionLog > 1;
            return 0;
        }
    }
    close $this->{maillogfh} if ($this->{maillogfh});
    if ($this->{maillogfilename} && $eF->( $this->{maillogfilename} )) {
        if ($unlink->($this->{maillogfilename})) {
            mlog($this->{self},"info: logfile ".de8($this->{maillogfilename})." removed") if $SessionLog;
        } else {
            mlog($this->{self},"error: unable to remove logfile ".de8($this->{maillogfilename}).' - '.$!);
        }
    }
    delete $this->{maillog};
    delete $this->{maillogfh};
    delete $this->{mailloglength};
    delete $this->{spambuf};
    delete $this->{maillogfilename};
    delete $this->{maillogparm};
    $this->{maillog} = 1 unless $NoMaillog;
    return 1;
}
