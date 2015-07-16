#line 1 "sub main::checkOptionList"
package main; sub checkOptionList {
    my ($value,$name,$init,$keepcomments)=@_;
    my $fromfile=0;
    my $fil;
    if ($value=~/^ *file: *(.+)/io) {

        # the option list is actually saved in a file.
        $fromfile=1;
        $fil=$1;
        $fil="$base/$fil" if $fil!~/^\Q$base\E/io;
        local $/;
        $FileUpdate{"$fil$name"} = $FileUpdate{$fil} = ftime($fil);
        $CryptFile{$fil} = 1 if $fil && exists $cryptConfigVars{$name};
        if (open(my $COL,'<',$fil)) {
            $value=join('',<$COL>);
            close $COL;
            my $enc;
            if (exists $CryptFile{$fil} && $value =~ /^(?:[a-zA-Z0-9]{2})+$/o) {
                $enc = ASSP::CRYPT->new($webAdminPassword,0);
                $value = $enc->DECRYPT($value);
            } elsif (exists $CryptFile{$fil}) {
                open(my $I,'>',$fil);
                binmode $I;
                print $I ASSP::CRYPT->new($webAdminPassword,0)->ENCRYPT($value);
                close $I;
                mlog(0,"info: file $fil is now stored encrypted, because it is used in secured config $name");
                $FileUpdate{"$fil$name"} = $FileUpdate{$fil} = ftime($fil);
            }
            $value =~ s/^$UTF8BOMRE//o;
            
            if ($value =~ /\s*#\s*assp-no-sync/ios) {
                $FileNoSync{$fil} = 1 if $WorkerNumber == 0;
            } else {
                delete $FileNoSync{$fil} if $WorkerNumber == 0;
            }

            %{$FileIncUpdate{"$fil$name"}} = ();

            while ($value =~ /(\s*#\s*include\s+([^\r\n]+)\r?\n)/io) {
                my $line = $1;
                my $ifile = $2;
                $ifile =~ s/([^\\\/])[#;].*/$1/go;
                $ifile =~ s/[\"\']//go;
                my $INCL;
                unless (open($INCL,'<',"$base/$ifile")) {
                    $value =~ s/$line//;
                    mlog(0,"AdminInfo: failed to open option list include file for reading '$base/$ifile' ($name): $!") if (! $calledfromThread);
                    $FileIncUpdate{"$fil$name"}{$ifile} = 0;
                    next;
                }
                my $inc = join('',<$INCL>);
                close $INCL;
                if (exists $CryptFile{"$base/$ifile"} && $inc =~ /^(?:[a-zA-Z0-9]{2})+$/o) {
                    $inc = ASSP::CRYPT->new($webAdminPassword,0)->DECRYPT($inc);
                } elsif ($enc) {
                    open($INCL,'>',"$base/$ifile");
                    binmode $INCL;
                    print $INCL $enc->ENCRYPT($inc);
                    close $INCL;
                    mlog(0,"info: file $base/$ifile is now stored encrypted, because it is used in secured config $name");
                    $CryptFile{"$base/$ifile"} = 1;
                }
                $inc =~ s/^$UTF8BOMRE//o;
                $inc = "\n$inc\n";
                if ($inc =~ /\s*#\s*assp-no-sync/ios) {
                    $FileNoSync{"$base/$ifile"} = 1 if $WorkerNumber == 0;
                } else {
                    delete $FileNoSync{"$base/$ifile"} if $WorkerNumber == 0;
                }
                $value =~ s/$line/$inc/;
                $FileIncUpdate{"$fil$name"}{$ifile} = ftime($ifile);
                mlog(0,"AdminInfo: option list include file '$ifile' processed for ($name)") if (!$init && ! $calledfromThread);
            }

            # clean off comments

            if (! $keepcomments) {
                $value =~ s/^[#;].*//go;
                $value =~ s/([^\\])[#;].*/$1/go;
            }

            # replace newlines (and the whitespace that surrounds them) with a |
            $value=~s/\r//go;
            $value=~s/\s*\n+\s*/\|/go unless wantarray;
        } else {
            mlog(0,"AdminInfo: failed to open option list file for reading '$fil' ($name): $!") if (! $calledfromThread);
            $value='';
        }
    }
    $value=~s/^\|+//o;
    $value=~s/([\\]\|)*\|+/$1\|/go;
    $value=~s/\s*\|/\|/go;
    $value=~s/\|\s*/\|/go;
    $value=~s/^\s*\|?//o;
    $value=~s/\|?\s*$//o;

    my $count = () = (wantarray ? $value =~ /(\n)/gos : $value =~ /([^\\]\|)/go);
    $count++ if length $value;

    if ($value =~ /(?:^|[^\\])(\(\s*\?\{.+?[^\\]\}\))/o) {
        return ("\x00\xff error: resulting regular expression in '$name' contains executable perl code '$1' - this is not allowed - the complete value is ignored!");
    }

    mlog(0,"option list file: '$fil' reloaded ($name) with ".nN($count)." records") if ($value && !$init && $fromfile && ! $calledfromThread);

    # set corrected value back in Config
    ${$name}=$Config{$name}=$value unless $fromfile;
    return wantarray ? split(/\s*\n+\s*/o,$value) : $value;
}
