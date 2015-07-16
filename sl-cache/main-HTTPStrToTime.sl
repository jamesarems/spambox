#line 1 "sub main::HTTPStrToTime"
package main; sub HTTPStrToTime {
  my $str=shift;
  if ($str=~/[SMTWF][a-z][a-z], (\d\d) ([JFMAJSOND][a-z][a-z]) (\d\d\d\d) (\d\d):(\d\d):(\d\d) GMT/o) {
      my %MoY=qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);
      return eval {
           my $t=Time::Local::timegm($6, $5, $4, $1, $MoY{$2}-1, $3-1900);
           $t<0 ? undef : $t;
      };
  }
}
