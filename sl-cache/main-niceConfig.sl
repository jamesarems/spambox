#line 1 "sub main::niceConfig"
package main; sub niceConfig {
 %ConfigNice = ();
 %ConfigDefault = ();
 %ConfigListBox = ();
 for my $idx (0...$#ConfigArray) {
      my $c = $ConfigArray[$idx];
      my $value;
      next if(@{$c} == 5) ;
      $ConfigNice{$c->[0]} =  ($c->[10] && $WebIP{$ActWebSess}->{lng}->{$c->[10]})
                              ? encodeHTMLEntities($WebIP{$ActWebSess}->{lng}->{$c->[10]})
                              : encodeHTMLEntities($c->[1]);
      $ConfigNice{$c->[0]} =~ s/<a\s+href.*<\/a>//io;
      $ConfigNice{$c->[0]} =~ s/'|"|\n//go;
      $ConfigNice{$c->[0]} =~ s/\\/\\\\/go;
      $ConfigNice{$c->[0]} = '&nbsp;' unless $ConfigNice{$c->[0]};
      $ConfigDefault{$c->[0]} = encodeHTMLEntities($c->[4]);
      $ConfigDefault{$c->[0]} =~ s/'|"|\n//go;
      $ConfigDefault{$c->[0]} =~ s/\\/\\\\/go;

      $value = ($qs{theButton} || $qs{theButtonX}) ? $qs{$c->[0]} : $Config{$c->[0]} ;
      $value = $Config{$c->[0]} if $qs{theButtonRefresh};

      if ($c->[3] == \&listbox) {
          $ConfigDefault{$c->[0]} = 0 unless $ConfigDefault{$c->[0]};
          foreach my $opt ( split( /\|/o, $c->[2] ) ) {
                my ( $v, $d ) = split( /:/o, $opt, 2 );
                $ConfigDefault{$c->[0]} = $d if ( $ConfigDefault{$c->[0]} eq $v );
                $ConfigListBox{$c->[0]} = $d if ( $value eq $v );
                $ConfigListBoxAll{$c->[0]}{$v} = $d;
          }
      } elsif ($c->[3] == \&checkbox) {
                $ConfigDefault{$c->[0]} = $ConfigDefault{$c->[0]} ? 'On' : 'Off';
                $ConfigListBox{$c->[0]} = $value ? 'On' : 'Off';
      } else {
          $ConfigDefault{$c->[0]} = '&nbsp;' unless $ConfigDefault{$c->[0]};
          $ConfigListBox{$c->[0]} = $value;
      }
 }
}
