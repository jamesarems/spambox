#line 1 "sub main::nixUsers"
package main; sub nixUsers {
  my ($uid,$gid); ($uid,$gid) = getUidGid($runAsUser,$runAsGroup) if ($runAsUser || $runAsGroup);
  if($ChangeRoot) {
    my $chroot;
    eval('$chroot=chroot($ChangeRoot)');
    if($@) {
      my $msg="request to change root to '$ChangeRoot' failed: $@";
      mlog(0,$msg);
      &downSPAMBOX($msg);
      exit(1);
    } elsif(! $chroot) {
      my $msg="request to change root to '$ChangeRoot' did not succeed: $!";
      mlog(0,$msg);
      &downSPAMBOX($msg);
      exit(1);
    } else {
      $chroot=$ChangeRoot; $chroot=~s/(\W)/\\$1/go;
      $base=~s/^$chroot//io;
      chdir("/");
      mlog(0,"successfully changed root to '$ChangeRoot' -- new base is '$base'");
    }
  }

  switchUsers($uid,$gid) if ($runAsUser || $runAsGroup);
}
