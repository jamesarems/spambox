#line 1 "sub main::isOk2Relay"
package main; sub isOk2Relay {
  my ($fh,$ip)=@_;
  return 1 if ($Con{$fh}->{acceptall} ||= matchIP($ip,'acceptAllMail',$fh,0));
  return 1 if $PopB4SMTPFile && PopB4SMTP($ip);
# failed all tests -- return 0
  return 0;
}
