#line 1 "sub main::DKIMOK"
package main; sub DKIMOK {
  my($fh,$message,$doBody)=@_;                  # returns: DKIMOK_Run
  my $retval = 1;
  $retval = 2 if ($Con{$fh}->{isDKIM});   # this is DKIM -> do not modify
  return $retval if !$DoDKIM;
  return DKIMOK_Run($fh,$message,$doBody);
}
