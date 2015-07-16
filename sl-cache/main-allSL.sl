#line 1 "sub main::allSL"
package main; sub allSL {
   my($rcpt,$from,$re)=@_;
   return 0 unless $rcpt;
   return 0 unless $re;
   return 0 unless $$re;
   return 1 if matchSL($from,$re,1);
   my $ret = 1;
   for (split(/\s+/o,$rcpt)) {
      if (! matchSL($_,$re,1)) {
         $ret = 0 ;
         last;
      }
   }
   return $ret;
}
