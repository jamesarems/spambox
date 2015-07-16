#line 1 "sub main::saveHashToFile"
package main; sub saveHashToFile {
   my ($file,$hash) = @_;
   unless ($file) {
       mlog(0,"error: coding error - saveHashToFile called without a specified file name");
       return;
   }
   unless (ref($hash) eq 'HASH') {
       mlog(0,"error: coding error - saveHashToFile called without a valid HASH reference");
       return;
   }
   my $LH;
   my $count;
   lock(%$hash) if is_shared(%$hash);
   unless (open($LH, '>',$file)) {
       mlog(0,"warning: can't open file '$file' to save hash (in saveHashToFile)");
       return;
   }
   binmode($LH);
   print $LH "\n";
   my @h;
   @h = sort keys %$hash;
   while (@h) {
      (my $k = shift @h) or next;
      (my $v = ${$hash}{$k}) or next;
      print $LH "$k\002$v\n";
      $count++;
   }
   eval{close $LH;};
   return $count;
}
