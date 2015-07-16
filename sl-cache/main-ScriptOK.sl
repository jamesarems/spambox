#line 1 "sub main::ScriptOK"
package main; sub ScriptOK {
  my($fh,$bd)=@_;
  my $this=$Con{$fh};
  my $DoScriptRe = $DoScriptRe;    # copy the global to local - using local from this point
  $DoScriptRe = $this->{overwritedo} if ($this->{overwritedo});   # overwrite requ by Plugin
  return 1 if ! $DoScriptRe;
  return ScriptOK_Run($fh,$bd);
}
