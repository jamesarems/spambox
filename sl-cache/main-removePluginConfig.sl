#line 1 "sub main::removePluginConfig"
package main; sub removePluginConfig {       # remove PluginConfig that was loaded in BEGIN section
   my $rplobj = shift;         # to cleanup GUI from that entries
   return unless $rplobj;
   my $cfg;
   my $i;
   my @rplconfig;
   eval{@rplconfig = $rplobj->get_config();};
   while (@rplconfig) {
      my $cfg = shift @rplconfig;
      my $i = 0;
      for my $idx (0...$#ConfigArray) {
          my $c = $ConfigArray[$idx];
          if (   $c->[0] eq $cfg->[0]
              && $c->[1] eq $cfg->[1]
              && $c->[2] eq $cfg->[2]
              && $c->[3] eq $cfg->[3]
              && $c->[4] eq $cfg->[4]
             )
          {
              splice (@ConfigArray,$i,1) ;
              last;
          }
          $i++;
      }
   }
}
