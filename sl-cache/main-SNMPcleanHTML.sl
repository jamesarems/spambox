#line 1 "sub main::SNMPcleanHTML"
package main; sub SNMPcleanHTML {
     my $str = shift;
     $str =~ s/<table.+?<\/table>//go;
     $str =~ s/<div.*?<\/div>//go;
     $str =~ s/<\/?(?:hr|br)[^>]*>//go;
     $str =~ s/<a +href.*?<\/a>//go;
     $str =~ s/<\/?span[^>]*>//go;
     $str =~ s/<input[^>]+>//go;
     $str =~ s/<\/?img[^>]+>//go;
     $str =~ s/<\/?(?:i|b|small|p)>//go;
     $str =~ s/<\/?font[^>]*>//o;
     return $str;
}
