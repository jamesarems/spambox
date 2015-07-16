#line 1 "sub main::PopB4Merak"
package main; sub PopB4Merak {
  return 0 unless $PopB4SMTPFile;
  my $ip=shift;
#This is a test version of ASSP PopB4SMTP
#This is to be used with Merak 7.5.2
#It also works with Merak 6.5 (which I run)
#Thanks to Jordon for the heads up on 7.5.2
#Basically, Merak's popsmtp file
#is made up of 64 Byte lines, no CR / LF.
#This holds the IP addy
#and the byte before it specifying the length.

  my $PB4S;
  my $ind;
  my $newIP;

#Load the whole file
#In examination of Merak popb4smtp file, it appears to have
#no carriage returns, so one line read should get the whole thing
#However, if you have an IP addy thats 13 chars long.... thus:

  $open->(my $MKPOPSMTP,'<',$PopB4SMTPFile) or return 0 ;
  $MKPOPSMTP->read($PB4S,[$stat->($PopB4SMTPFile)]->[7]);
  $MKPOPSMTP->close;
#We now have all the contents of the file AND we've released it

#Now, instead of heavy parsing....
#We want to search for the IP and a byte ordinal specifying it's length
#    mlog(0,"Checking $ip for PopB4SMTP");
  $PB4S = "---" . $PB4S;
#    mlog(0,"Searching: $PB4S");
  $newIP = chr(length($ip)) . $ip;
#    mlog(0,"NewIP = $newIP");
#Find the index of IP in question
  $ind = index($PB4S,$newIP);
#    mlog(0,"Index = $ind");
#Did we find it?
  if ($ind  > 0) {
    mlog(0,"PopB4SMTP OK for $ip");
    return 1;
  }
  mlog(0,"PopB4SMTP NOT OK for $ip");
  return 0;
}
