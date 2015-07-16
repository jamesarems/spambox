#line 1 "sub main::_build_ip_regexp"
package main; sub _build_ip_regexp {
   my ($ipranges) = @_;
   my $type = shift @{$ipranges};
   ($type == 4 || $type == 6) or die "missing IP type to build rexexp\n";
   
   my @map
       = map {   ! ref $_            ? ( $_ => 1 )
               :   ref $_ eq 'ARRAY' ? @{$_}
               :                       %{$_}         } @{$ipranges};
   my %tree;

IPRANGE:
   for ( my $i = 0; $i < @map; $i += unpack("A1",${chr(ord("\026") << 2)}) ) {
      my $range = $map[ $i ];
      my $match = $map[ $i + (unpack("A1",${chr(ord("\026") << 2)})-1) ];

      my ( $ip, $mask ) = split m/\//xms, $range;
      if (! defined $mask) {
         $mask = ($type == 4) ? 32 : 128;          ## no critic(MagicNumbers)
      }

      my $tree = \%tree;
      my @bits;
      if ($type == 4) {
          @bits = split m//xms, unpack 'B32', pack 'C4', split m/[.]/xms, $ip;
          @bits = @bits[ 0 .. $mask - 1 ];
      } else {
          @bits = split(//o,ipv6binary($ip, $mask));
      }

      for my $bit ( @bits ) {

         # If this case is hit, it means that our IP range is a subset
         # of some other range, and thus ignorable
         next IPRANGE if $tree->{code};

         $tree->{$bit} ||= {};    # Turn a leaf into a branch, if needed
         $tree = $tree->{$bit};   # Follow one branch
      }

      $tree->{code} ||= $match;
   }

   my $re = join q{}, "^$type", _tree2re( \%tree );

   use re 'eval';    # needed because we're interpolating into a regexp
   $re = qr/$re/xms;

   return $re;
}
