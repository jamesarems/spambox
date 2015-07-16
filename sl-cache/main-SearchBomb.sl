#line 1 "sub main::SearchBomb"
package main; sub SearchBomb {
    my ($name, $srch)=@_;

    my $extLog = $AnalyzeLogRegex && ! $silent && [caller(1)]->[3] =~ /analyze/io;

    $incFound = '';
    my $fil=$Config{"$name"};
    return 0 unless $fil;
    $addCharsets = 1 if $name eq 'bombCharSets';
    my $text;
    if ($name ne 'bombSubjectRe') {
       my $mimetext = cleanMIMEBody2UTF8(\$srch);
       if ($mimetext || $srch =~ /^$HeaderRe/io) {
           $text =  cleanMIMEHeader2UTF8(\$srch,0);
           $mimetext =~ s/\=(?:\015?\012|\015)//go;
           $mimetext = decHTMLent(\$mimetext);
           $text .= $mimetext;
       } else {
           $text = decodeMimeWords2UTF8($srch)
       }
    } else {
       $text = $srch;
    }
    unicodeNormalize(\$text);
    $srch = $text;
    $text = "\r\n" . $text;
    $srch .= transliterate(\$text, 1) if $DoTransliterate;
    undef $text;
    $addCharsets = 0;
    my @complex;
    if($fil=~/^\s*file:\s*(.+)\s*$/io) {
        $fil=$1;
        open (my $BOMBFILE, '<',"$base/$fil");
        my $counter=0;
        my $complexStartLine;
        while (my $i = <$BOMBFILE>)  {
            $counter++;
            $i =~ s/$UTF8BOMRE//o;
            unicodeNormalizeRe(\$i);
            $i =~ s/\<\<\<(.*?)\>\>\>/$1/o;
            $i =~ s/!!!(.*?)!!!//o;
            $i =~ s/a(?:ssp)?\\?-do?\\?-n(?:ot)?\\?-o(?:ptimize)?\\?-r(?:egex)?//iso;
            if ($i =~ /(^\s*#\s*include\s+)(.+)/io) {
                my $fn = $2;
                $i = $1;
                $fn =~ s/([^\\\/])[#;].*/$1/go;
                $i .= $fn;
            } else {
                $i =~ s/^#.*//go;
                $i =~ s/([^\\])#.*/$1/go;
            }
            $i =~ s/^;.*//go;
            $i =~ s/([^\\]);.*/$1/go;
            $i =~ s/\r//go;
            $i =~ s/\s*\n+\s*//go;
            $i =~ s/\s+$//o;
            $i =~ s/(([^\\]?)\$\{\$([a-z][a-z0-9]+)\})/(defined ${$3}) ? $2.${$3} : $1/oige if $AllowInternalsInRegex;

            next if !$i;

            if (($i =~ /^\~?\Q$complexREStart\E\s*$/o || @complex) && $i !~ /^\Q$complexREEnd\E\d+\}\)(?:\s*\=\>\s*(?:-{0,1}\d+\.*\d*)?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?)?$/o) {
                $complexStartLine = $counter if !$complexStartLine && $i =~ /^\~?\Q$complexREStart\E\s*$/o;
                if ($i !~ /^\s*#\s*include\s+.+/io) {
                    push @complex, $i;
                    next;
                }
            } elsif ($i =~ /^\Q$complexREEnd\E\d+\}\)(?:\s*\=\>\s*([+\-]?(?:0?\.\d+|\d+\.\d+|\d+))?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?)?$/o) {
                push @complex, $i;
                $i = join('|', @complex);
                @complex = ();
            }

            $i =~ s/(\~([^\~]+)?\~|([^\|]+)?)\s*\=\>\s*([+\-]?(?:0?\.\d+|\d+\.\d+|\d+))?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?/$1/go;
            next if !$i;
            print "$name: line:$counter-$fil\n" if $extLog;

            my $line;
            my $reg = $i;
            my $file = $fil;
            my $found;
            my $INCFILE;
            if ($i =~ /^\s*#\s*include\s+(.+)\s*/io && (open $INCFILE, '<',"$base/$1")) {
                $line = 0;
                $file = $1;
                my @complexInc;
                my $complexIncStart;
                while (my $ii = <$INCFILE>) {
                    $line++;

                    $ii =~ s/$UTF8BOMRE//o;
                    unicodeNormalizeRe(\$ii);
                    $ii =~ s/\<\<\<(.*?)\>\>\>/$1/o;
                    $ii =~ s/!!!(.*?)!!!//o;
                    $ii =~ s/a(?:ssp)?\\?-do?\\?-n(?:ot)?\\?-o(?:ptimize)?\\?-r(?:egex)?//iso;
                    $ii =~ s/^[#;].*//go;
                    $ii =~ s/([^\\])[#;].*/$1/go;
                    $ii =~ s/\r//go;
                    $ii =~ s/\s*\n+\s*//go;
                    $ii =~ s/\s+$//o;
                    next if !$ii;
                    $ii =~ s/(([^\\]?)\$\{\$([a-z][a-z0-9]+)\})/(defined ${$3}) ? $2.${$3} : $1/oige if $AllowInternalsInRegex;

                    if (@complex)  {                   # complex regex started in upper file
                        push @complex, $ii;
                        next;
                    }
                                                       # complex regex started in include file
                    if (($ii =~ /^\~?\Q$complexREStart\E\s*$/o || @complexInc) && $ii !~ /^\Q$complexREEnd\E\d+\}\)(?:\s*\=\>\s*(?:-{0,1}\d+\.*\d*)?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?)?$/o) {
                        $complexIncStart = $line if !$complexIncStart && $ii =~ /^\~?\Q$complexREStart\E\s*$/o;
                        push @complexInc, $ii;
                        next;
                    } elsif ($ii =~ /^\Q$complexREEnd\E\d+\}\)(?:\s*\=\>\s*(?:-{0,1}\d+\.*\d*)?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?)?$/o) {
                        push @complexInc, $ii;
                        $ii = join('|', @complexInc);
                        @complexInc = ();
                    }

                    $ii =~ s/(\~([^\~]+)?\~|([^\|]+)?)\s*\=\>\s*([+\-]?(?:0?\.\d+|\d+\.\d+|\d+))?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?/$1/o;
                    next if !$ii;
                    print "$name: line:$line-$fil\n" if $extLog;
                    
                    $found = '';
                    eval{$found = $1 || $2 if $srch =~ m/($ii)/i;};
                    if ($@) {
                        mlog(0,"ConfigError: '$name' regular expression error in line $counter of file $fil - line $line of include '$file' for '$ii': $@");
                        next;
                    }
                    if ($found)
                    {
                        mlog(0,"Info: '$name' regular expression '$ii' match in line $counter of file $fil - line ".($complexIncStart?"$complexIncStart-$line":$line)." of include file '$file' with '$found' ") if $regexLogging or $BombLog;
                        close ($INCFILE);
                        $incFound = "<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('$fil',1);\" onmouseover=\"showhint('edit file $fil', this, event, '250px', '1'); return true;\">$Config{$name}\[line $counter\]</a>|incl:<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('$file',1);\" onmouseover=\"showhint('edit file $file', this, event, '250px', '1'); return true;\">$file\[line ".($complexIncStart?"$complexIncStart-$line":$line)."\]</a>";

                        close ($BOMBFILE);
                        return $ii;
                    }
                    $complexIncStart = 0;
                }
                close $INCFILE;
                next;
            } elsif ($i =~ /^\s*#\s*include\s+(.+)\s*/io) {
                mlog(0,"ConfigError: '$name' unable to open include file $1 in line $counter of '$file'");
                next;
            } else {
                $found = '';
                eval{$found = $1 || $2 if $srch =~ m/($i)/i;};
                if ($@) {
                    mlog(0,"ConfigError: '$name' regular expression error in line $counter of '$file' for '$reg': $@");
                    next;
                }
            }
            if ($found)
            {
                mlog(0,"Info: '$name' regular expression '$reg' match in line ".($complexStartLine?"$complexStartLine-$counter":$counter)." of '$file' with '$found' ") if $regexLogging or $BombLog;
                close ($BOMBFILE);
                $incFound = "<a href=\"javascript:void(0);\" onclick=\"javascript:popFileEditor('$file',1);\" onmouseover=\"showhint('edit file $file', this, event, '250px', '1'); return true;\">$Config{$name}\[line ".($complexStartLine?"$complexStartLine-$counter":$counter)."\]</a>";
                return $i;
            }
            $complexStartLine = 0;
        }
        close ($BOMBFILE);
    } else {
        my $regex;
        $fil =~ s/(\~([^\~]+)?\~|([^\|]+)?)\s*\=\>\s*([+\-]?(?:0?\.\d+|\d+\.\d+|\d+))?\s*(?:\s*\:\>\s*(?:[nNwWlLiI\+\-\s]+)?)?/$1/o; # skip weighted regexes
        $fil =~ s/(([^\\]?)\$\{\$([a-z][a-z0-9]+)\})/(defined ${$3}) ? $2.${$3} : $1/oige if $AllowInternalsInRegex;
        my @reg;
        my $bd=0;
        my $sk;
        my $t;
        foreach my $s (split('',$fil)) {
            if ($s eq '\\') {
                $sk = 1;
                $t .= $s;
                next;
            } elsif ($sk == 1) {
                $sk = 0;
                $t .= $s;
                next;
            }
            if ($s eq '(' or $s eq '[' or $s eq '{') {
                $bd++;
                $t .= $s;
                next;
            } elsif ($s eq ')' or $s eq ']' or $s eq '}') {
                $bd--;
                $t .= $s;
                next;
            }
            if ($bd > 0) {
                $t .= $s;
                next;
            } elsif ($s eq '|') {
                push @reg, $t;
                $t = '';
                $sk = 0;
                next;
            } else {
                $t .= $s;
            }
        }
        push @reg,$t if $t;
        
        while (@reg) {
            $regex = shift @reg;
            print "$name: $regex\n" if $extLog;
            unicodeNormalizeRe(\$regex);
            if (my ($i) = eval{$srch =~ m/($regex)/i}) {
                mlog(0,"Info: '$name' regular expression '$regex' match with '$i' ") if $regexLogging or $BombLog;
                $incFound = encodeHTMLEntities($i);
                return $i;
            }
        }
        if ($@) {
            mlog(0,"ConfigError: '$name' regular expression error of '$fil' for '$name': $@");
        }
    }
    return 0;
}
