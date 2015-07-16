#line 1 "sub main::FromStrictOK_Run"
package main; sub FromStrictOK_Run {
    my $fh = shift;
    my $this = $Con{$fh};
    d('FromStrictOK');

    return 1 if $this->{FromStrictOK};
    $this->{FromStrictOK} = 1;
    my $ip = $this->{ip};
    $ip = $this->{cip} if $this->{ispip} && $this->{cip};
    return 1 if !$this->{mailfrom};
    skipCheck($this,'sb','ro','aa','co') && return 1;
    return 1 if $ip =~ /$IPprivate/o;
    return 1 if $this->{whitelisted} && !$DoNoFromWL;
    return 1 if (($this->{noprocessing} & 1) && !$DoNoFromNP);
    return 1 if $this->{mailfrom} =~ /news/io;

    my $tlit = tlit($DoNoFrom);

    if ( $this->{header} !~ /(?:^|\n)from:\s*([^\n]+)/ios ) {
        $this->{prepend}       = '[FromMissing]';
        $this->{messagereason} = 'From missing';
        mlog( $fh, "$tlit ($this->{messagereason})" ) if $DoNoFrom >= 2;
        return 1 if $DoNoFrom == 2;
        pbAdd( $fh, $this->{ip}, 'nofromValencePB', 'From-missing' );

        return 1 if $DoNoFrom == 3;
        return 0;
    }
    return 1;
}
