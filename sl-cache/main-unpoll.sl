#line 1 "sub main::unpoll"
package main; sub unpoll {
   my ($fhh,$action) = @_ ;
   $fhh = $Con{$fhh}->{self} if exists $Con{$fhh} && $Con{$fhh}->{self};
   if ($IOEngineRun == 0) {
       $fhh = $WebConH{$fhh} if exists $WebConH{$fhh};
       $fhh = $StatConH{$fhh} if exists $StatConH{$fhh};

       eval{$action->mask($fhh => 0);};

       if (exists $Con{$fhh} && $ConTimeOutDebug) {
           my $m = &timestring();
           my ($package, $file, $line) = caller;
           if ($Con{$fhh}->{type} eq 'C'){
               $Con{$fhh}->{contimeoutdebug} .= "$m client unpoll from $package $file $line\n" ;
           } else {
               $Con{$Con{$fhh}->{friend}}->{contimeoutdebug} .= "$m server unpoll from $package $file $line\n" if exists $Con{$Con{$fhh}->{friend}};
           }
       }
       if (my $fno = $action->[3]{$fhh}) {         # poll fd workaround
           delete $action->[3]{$fhh};
           delete $action->[0]{$fno}{$fhh};
           unless (%{$action->[0]{$fno}}) {
               delete $action->[0]{$fno};
               delete $action->[1]{$fno};
               delete $action->[2]{$fhh};
           }
       }
   } else {
       if (exists $Con{$fhh} && $ConTimeOutDebug) {
           my $m = &timestring();
             my ($package, $file, $line) = caller;
           if ($Con{$fhh}->{type} eq 'C'){
               $Con{$fhh}->{contimeoutdebug} .= "$m client unselect from $package $file $line\n" ;
           } else {
               $Con{$Con{$fhh}->{friend}}->{contimeoutdebug} .= "$m server ununselect from $package $file $line\n" if exists $Con{$Con{$fhh}->{friend}};
           }
       }
       $action->remove($fhh);
   }
}
