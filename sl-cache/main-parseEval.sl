#line 1 "sub main::parseEval"
package main; sub parseEval {
    my $line = shift;
    d("parseEval-line: $line");
    $line =~ s/\r?\n//go;
    $line =~ s/^\s+//o;
    $line =~ s/\s+$//o;
#    return (undef,undef) unless ($line =~ /^(\&?[a-zA-Z0-9_]+)\s*(\(.*\))?[;\s]*$/o);
    return (undef,undef) unless ($line =~ /^(\&?[a-zA-Z0-9_]+)(?:(?:\s*\(|\s+)(.*?)\)?)?[;\s]*$/o);
    my $sub = $1;
    my $parm = $2;
    d("parseEval-parse-regex: $sub $parm");
    $parm =~ s/^\((.*)\)$/$1/o;
    $parm =~ s/[\s\;]+$//o;
    d("parseEval-cleaned: $sub $parm");
    $parm =~ s/\$([a-zA-Z0-9_]+)/\${$1}/go;
    $parm =~ s/\@([a-zA-Z0-9_]+)/\@{$1}/go;
    $parm =~ s/\%([a-zA-Z0-9_]+)/\%{$1}/go;
    $parm =~ s/\&([a-zA-Z0-9_]+)/\&{$1}/go;
    d("parseEval-parsed: $sub $parm");
    return ($sub,$parm);
}
