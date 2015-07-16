#line 1 "sub main::sayMessageOK"
package main; sub sayMessageOK {
    my $fh = shift;
    my $this = $Con{$fh};
    d('sayMessageOK');
    return if $this->{sayMessageOK} eq 'already';
    return if $this->{deleteMailLog};
    &makeSubject($fh);
    ccMail($fh,$this->{mailfrom},$sendHamInbound,\$this->{header},\$this->{subject},$this->{rcpt}) ;
    return unless $this->{sayMessageOK};
    $this->{messagereason}="Bonus: Message OK";
    pbAdd($fh,$this->{ip},'okValencePB',"MessageOK",2,1);
    $this->{prepend}="[MessageOK]";
    mlog($fh,"$this->{sayMessageOK}",0,2) ;
    $Stats{bhams}++;
    $this->{sayMessageOK} = 'already';
}
