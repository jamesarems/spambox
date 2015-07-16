#line 1 "sub main::DKIMpreCheckOK"
package main; sub DKIMpreCheckOK {
   my $fh = shift;
   return 1 if (! $CanUseDKIM);
   return 1 if (! $DoDKIM);
   return 1 unless $DKIMCacheInterval;
   return DKIMpreCheckOK_Run($fh);
}
