#line 1 "sub main::getUidGid"
package main; sub getUidGid { my ($uname,$gname)=@_;
  return if $AsAService;
  my $rname="root";
  eval('getgrnam($rname);getpwnam($rname);');
  if($@) {
# windows pukes "unimplemented" for these -- just skip it
    mlog(0,"warning: uname and/or gname are set ($uname,$gname) but getgrnam / getpwnam give errors: $@");
    return;
  }
  my $gid;
  if($gname) {
    $gid = getgrnam($gname);
    if(defined $gid) {
    } else {
      my $msg="could not find gid for group '$gname' -- not switching effective gid -- quitting";
      mlog(0,$msg);
      &downSPAMBOX($msg);
      exit(1);
    }
  }
  my $uid;
  if($uname) {
    $uid = getpwnam($uname);
    if(defined $uid) {
    } else {
      my $msg="could not find uid for user '$uname' -- not switching effective uid -- quitting";
      mlog(0,$msg);
      &downSPAMBOX($msg);
      exit(1);
    }
  }
  ($uid,$gid);
}
