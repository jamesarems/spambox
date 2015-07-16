#line 1 "sub main::DMARCget"
package main; sub DMARCget {
   my $fh = shift;
   return unless $ValidateSPF && $DoDKIM && $DoDMARC;
   return DMARCget_Run($fh);
}
