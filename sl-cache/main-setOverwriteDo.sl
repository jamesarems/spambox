#line 1 "sub main::setOverwriteDo"
package main; sub setOverwriteDo {                # overwrite the configured Do.. with plDo
   my ($fh,$orgDoName,$plDo,$pl) = @_;
   my $orgDo = $$orgDoName;
   my $this = $Con{$fh};
   my $log = $SessionLog >= 2 || (defined ${$pl.'Log'} && ${$pl.'Log'} >= 2);
   my %do = (
       0 => 'disabled',
       1 => 'block',
       2 => 'monitor',
       3 => 'score',
       4 => 'test'
   );
   $this->{messagereason} = '';
   $this->{overwritedo} = '';
   return if ($plDo == 1);          # no ovr if plDo == 1  block
   $this->{overwritedo} = $plDo;
   if ($plDo == 3) {          # all ovr if plDo = 3  score
       mlog($fh,"info: the setting of '$orgDoName' ($do{$orgDo}) is temporarily overwritten by the 'Do$pl' setting of ($do{$plDo})") if $plDo != $orgDo && $log;
       return;
   }
   if ($orgDo == 1) {         # ovr if plDo == 2 monitor and orgDo == 1 block
       mlog($fh,"info: the setting of '$orgDoName' ($do{$orgDo}) is temporarily overwritten by the 'Do$pl' setting of ($do{$plDo})") if $plDo != $orgDo && $log;
       return;
   }
   $this->{overwritedo} = '';       # no ovr for the rest
   return;
}
