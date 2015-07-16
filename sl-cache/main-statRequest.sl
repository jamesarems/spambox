#line 1 "sub main::statRequest"
package main; sub statRequest {
 my ($tempfh,$fh,$h,$d)=@_;
 my $head; $head = $$h if $h;
 my $data; $data = $$d if $d;
 my $k;
 my $v;
 %statRequests=(
  '' => \&ConfigStatsRaw,
  '/' => \&ConfigStatsRaw,
  '/raw' => \&ConfigStatsRaw,
  '/xml' => \&ConfigStatsXml,    # Can be expanded to display in different formats like this
 );
 my $i=0;
 # %head -- public hash
 (%head)=map{++$i % 2 ? lc $_ : $_} map{/^([^ :]*)[: ]{0,2}(.*)/o} split(/\r\n/o,$head);
 my ($page,$qs)=($head{get} || $head{head} || $head{post})=~/^([^\? ]+)(?:\?(\S*))?/o;
 if(defined $data) { # GET, POST order
  $qs.='&' if ($qs ne '');
  $qs.=$data;
 }
 $qs=~y/+/ /;
 $i=0;
 # parse query string, get rid of google autofill
 # %qs -- public hash
 (%qs)=map{my $t = $_; $t =~ s/(e)_(mail)/$1$2/gio if ++$i % 2; $t} split(/[=&]/o,$qs);
 while (($k,$v) = each %qs) {$qs{$k}=~s/%([0-9a-fA-F]{2})/pack('C',hex($1))/geo}
 my $ip=$fh->peerhost();
 my $port=$fh->peerport();
 mlog(0,"stat connection from $ip:$port" . ($page ? " - page: $page" : '') );

 $Stats{statConn}++;

 if (defined ($v=$statRequests{lc $page})) { print $tempfh $v->(\$head,\$qs); }
}
