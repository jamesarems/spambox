#line 1 "sub main::allSH"
package main; sub allSH {
   my($rcpt,$re)=@_;
   return 0 unless $rcpt;
   return 0 unless $re;
   return 0 unless $$re;
   my $ret = 1;
   for (split(/\s+/o,$rcpt)) {
      if (! matchSL($_,$re,1)) {
         $ret = 0 ;
         last;
      }
   }
   return $ret;
}
