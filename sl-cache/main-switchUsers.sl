#line 1 "sub main::switchUsers"
package main; sub switchUsers { my ($uid,$gid)=@_;
  return if $AsAService;
  my($uname,$gname)=($runAsUser,$runAsGroup);
  $>=0;
  if($> != 0) {
    my $msg="requested to switch to user/group '$uname/$gname' but cannot set effective uid to 0 -- quitting; uid is $>";
    mlog(0,$msg);
    &downSPAMBOX($msg);
    exit(1);
  }
  $<=0;
  if($gid) {
    $)=$gid;
    if($)+0==$gid) {
      mlog(0,"switched effective gid to $gid ($gname)");
    } else {
      my $msg="failed to switch effective gid to $gid ($gname) -- effective gid=$) -- quitting";
      mlog(0,$msg);
      &downSPAMBOX($msg);
      exit(1);
    }
    $(=$gid;
    if($(+0==$gid) {
      mlog(0,"switched real gid to $gid ($gname)");
    } else {
      mlog(0,"failed to switch real gid to $gid ($gname) -- real uid=$(");
    }
  }
  if($uid) {
# do it both ways so linux and bsd are happy
   $< = $> = $uid;
    if($>==$uid) {
      mlog(0,"switched effective uid to $uid ($uname)");
      $switchedUser = 1;
    } else {
      my $msg="failed to switch effective uid to $uid ($uname) -- real uid=$< -- quitting";
      mlog(0,$msg);
      &downSPAMBOX($msg);
      exit(1);
    }
    if($<==$uid) {
      mlog(0,"switched real uid to $uid ($uname)");
      $switchedUser = 1;
    } else {
      mlog(0,"failed to switch real uid to $uid ($uname) -- real uid=$<");
    }
  }
}
