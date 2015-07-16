#line 1 "sub main::loadHashFromFile"
package main; sub loadHashFromFile {
   my ($file,$hash) = @_;
   unless ($file) {
       mlog(0,"error: coding error - loadHashFromFile called without a specified file name");
       return;
   }
   unless (ref($hash) eq 'HASH') {
       mlog(0,"error: coding error - loadHashFromFile called without a valid HASH reference");
       return;
   }
   my $LH;
   my $count;
   lock(%$hash) if is_shared(%$hash);
   unless (open($LH, '<',$file)) {
       mlog(0,"warning: can't open file '$file' to load hash (in loadHashFromFile)");
       return;
   }
   binmode($LH);
   %{$hash} = ();
   while (<$LH>) {
     my ($k,$v) = split/\002/o;
     $v =~ s/(?:\r|\n)$//go;
     if ($k && $v) {
       $hash->{$k}=$v;
       $count++;
     }
   }
   eval{close $LH;};
   return $count;
}
