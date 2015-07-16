#line 1 "sub main::BombOK"
package main; sub BombOK {
    my($fh,$bd)=@_;
    my $this=$Con{$fh};
    return 1 if $this->{bombdone} == 1;
    my $DoBombRe = $DoBombRe;    # copy the global to local - using local from this point
    $DoBombRe = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
    if (! $DoBombRe){
        $this->{bombdone}=1;
        return 1;
    }
    return BombOK_Run($fh,$bd);
}
