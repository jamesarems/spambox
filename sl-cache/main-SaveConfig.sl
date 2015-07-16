#line 1 "sub main::SaveConfig"
package main; sub SaveConfig {
 return if $WorkerNumber != 0;
 mlog( 0, "saving config" ,1);
 my $content;
 my $SC;
 local $/ = undef;
 open($SC,'>',\$content);

 my $enc = ASSP::CRYPT->new($Config{webAdminPassword},0);

 for my $idx (0...$#ConfigArray) {
   my $c = $ConfigArray[$idx];
   next if $c->[0] eq "0";
   if (exists $cryptConfigVars{$c->[0]}) {
       my $var = $Config{$c->[0]} ? $enc->ENCRYPT($Config{$c->[0]}) : '';
       print $SC "$c->[0]:=$var\n";
   } else {
       print $SC "$c->[0]:=$Config{$c->[0]}\n";
   }
 }
 foreach my $c (sort keys %ConfigAdd) {
   if (exists $cryptConfigVars{$c}) {
       my $var = $ConfigAdd{$c} ? $enc->ENCRYPT($ConfigAdd{$c}) : '';
       print $SC "$c:=$var\n";
   } else {
       print $SC "$c:=$ConfigAdd{$c}\n";
   }
 }
 print $SC "ConfigSavedOK:=1\n";
 close $SC;

 if (open($SC, '<', "$base/spambox.cfg")) {
     my $current = (<$SC>);
     close $SC;
     if ($current eq $content) {
         mlog(0,"info: no configuration changes detected - nothing to save - file $base/spambox.cfg is unchanged");
         return;
     }
 } else {
     mlog(0,"warning: unable to read the current config in $base/spambox.cfg");
 }

 unlink("$base/spambox.cfg.bak.bak.bak") or mlog(0,"error: unable to delete file $base/spambox.cfg.bak.bak.bak - $!");
 rename("$base/spambox.cfg.bak.bak","$base/spambox.cfg.bak.bak.bak") or mlog(0,"error: unable to rename file $base/spambox.cfg.bak.bak to $base/spambox.cfg.bak.bak.bak - $!");
 rename("$base/spambox.cfg.bak","$base/spambox.cfg.bak.bak") or mlog(0,"error: unable to rename file $base/spambox.cfg.bak to $base/spambox.cfg.bak.bak - $!");
 $FileUpdate{"$base/spambox.cfgspamboxCfg"} = 0;

 open($SC,'>',"$base/spambox.cfg.tmp");
 print $SC $content;
 close $SC;
 mlog(0,"info: saved config to $base/spambox.cfg.tmp - which is now renamed to $base/spambox.cfg");
 
 rename("$base/spambox.cfg","$base/spambox.cfg.bak") or mlog(0,"error: unable to rename file $base/spambox.cfg to $base/spambox.cfg.bak - $!");
 rename("$base/spambox.cfg.tmp","$base/spambox.cfg") or mlog(0,"error: unable to rename file $base/spambox.cfg.tmp to $base/spambox.cfg - $!");
 $asspCFGTime = $FileUpdate{"$base/spambox.cfgspamboxCfg"} = ftime("$base/spambox.cfg");
 mlog( 0, "finished saving config" ,1);
}
