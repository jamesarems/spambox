#line 1 "sub main::RcptRegexMake"
package main; sub RcptRegexMake {
  my ($string,$how) = @_;
  if ($how) {
    $string =~ s/\./\\./go;
    $string =~ s/\*/(.*)/go;
    $string =~ s/\@/\\@/go;
    $string =~ s/\+/(.+)/go;    # hidden option
    $string =~ s/\?/(.?)/go;    # hidden option
    $string =~ s/\;/(.)/go;     # hidden option
    $string =~ s/(\.[*+])/$1?/go;
    $string = "^".$string."\$";
  } else {
    my $i = 1;
    while ($string =~ /\*/o && $i < 10) {
       $string =~ s/\*/\$$i/o ;
       $i++;
    }
  }
  return $string;
}
