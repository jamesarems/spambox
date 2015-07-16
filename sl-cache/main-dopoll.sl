#line 1 "sub main::dopoll"
package main; sub dopoll {
   my ($fh,$action,$mask) = @_ ;
   my $fno;
   $fh = $Con{$fh}->{self} if exists $Con{$fh} && $Con{$fh}->{self};
   $fh = $WebConH{$fh} if exists $WebConH{$fh};
   $fh = $StatConH{$fh} if exists $StatConH{$fh};
   if ($IOEngineRun == 0) {
       $fno = fileno($fh);
       eval{$action->mask($fh => $mask);};
       if ($@) {
           if (exists $WebConH{$fh} or exists $StatConH{$fh}) {
               &WebDone($fh);
           } else {
               done($fh);
           }
       } else {
           $action->[3]{$fh} = $fno if $fno;
       }
   } else {
       $action->add($fh);
   }
}
