#line 1 "sub main::PrintConfigSettings"
package main; sub PrintConfigSettings {
    my ($desc, $F);
    open( $F, '>',"$base/notes/configdefaults.txt" );
    my %ConfigNice = ();
    my %ConfigDefault = ();
    my %ConfigNow = ();

    for my $idx (0...$#ConfigArray) {
            my $c = $ConfigArray[$idx];
            next if ( @{$c} == 5 );
            $ConfigNice{ $c->[0] } = encodeHTMLEntities( $c->[1] );
            $ConfigNice{ $c->[0] } =~ s/<a\s+href.*?<\/a>//io;
            $ConfigNice{ $c->[0] } =~ s/'|"|\n//go;
            $ConfigNice{ $c->[0] } =~ s/\\/\\\\/go;
            $ConfigNice{ $c->[0] } = '&nbsp;' unless $ConfigNice{ $c->[0] };
            $ConfigDefault{ $c->[0] } = encodeHTMLEntities( $c->[4] );
            $ConfigDefault{ $c->[0] } =~ s/'|"|\n//go;
            $ConfigDefault{ $c->[0] } =~ s/\\/\\\\/go;
            $ConfigNow{ $c->[0] } = encodeHTMLEntities( $Config{$c->[0]} );
            $ConfigNow{ $c->[0] } =~ s/'|"|\n//go;
            $ConfigNow{ $c->[0] } =~ s/\\/\\\\/go;

            if ( $c->[3] == \&listbox ) {
                $ConfigDefault{ $c->[0] } = 0 unless $ConfigDefault{ $c->[0] };
                $ConfigNow{ $c->[0] } = 0 unless $ConfigNow{ $c->[0] };
                foreach my $opt ( split( /\|/o, $c->[2] ) ) {
                    my ( $v, $d ) = split( /:/o, $opt, 2 );
                    $ConfigDefault{ $c->[0] } = $d
                      if ( $ConfigDefault{ $c->[0] } eq $v );
                    $ConfigNow{ $c->[0] } = $d
                      if ( $ConfigNow{ $c->[0] } eq $v );
                }
            } elsif ( $c->[3] == \&checkbox ) {
                $ConfigDefault{ $c->[0] } =
                  $ConfigDefault{ $c->[0] } ? 'On' : 'Off';
                $ConfigNow{ $c->[0] } =
                  $ConfigNow{ $c->[0] } ? 'On' : 'Off';

            } else {
                $ConfigDefault{ $c->[0] } = ' '
                  unless $ConfigDefault{ $c->[0] };
                $ConfigNow{ $c->[0] } = ' '
                  unless $ConfigNow{ $c->[0] };
            }
    }


    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
	    $desc = $c->[4] if $c->[0] eq "0";
        $desc =~ s/\<[^<>]*\>//go;
        print $F "# $desc #\n" if $c->[0] eq "0";
        next if $c->[0] eq "0";

        my $c0 = uc $c->[0];

        if ( $c->[4] ne $Config{ $c->[0] } ) {

            print $F "$c->[0] -- $ConfigNice{ $c->[0] }: $ConfigNow{ $c->[0] } (Default: $ConfigDefault{ $c->[0] }) \n";
        } else {

            #print F "$c->[0] -- $desc: $Config{$c->[0]}  \n";
        }
    }
    close $F;
    chmod 0660, "$base/notes/configdefaults.txt";

    open( $F, '>',"$base/notes/config.txt" );
    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
        $desc = $c->[7];
        if ($desc) {
          $desc =~ s/\<b\>//go;
          $desc =~ s/\<i\>//go;
          $desc =~ s/\<p\>//go;
          $desc =~ s/\<small\>//go;
          $desc =~ s/\<br \/\>//go;
          $desc =~ s/\<\/i\>//go;
          $desc =~ s/\<\/b\>//go;
          $desc =~ s/\<\/p\>//go;
          $desc =~ s/\<\/small\>//go;
          $desc =~ s/\<[^<>]*\>//go;
        }

        my $c0  = uc $c->[0];
        my $act; $act = "actual: $Config{$c->[0]}" if $Config{ $c->[0] };
        my $def = $c->[4] ? "default: $c->[4]" : '' ;
        print $F "$c->[0]: $c->[1] -- $desc $def \n"
          if $Config{ $c->[0] } eq $c->[4] && $c->[0] ne "0";
        print $F "$c->[0]: $c->[1] -- $desc $def  \n"
          if $Config{ $c->[0] } ne $c->[4] && $c->[0] ne "0";
        $desc = $c->[4] if $c->[0] eq "0";
        $desc = '' unless $desc;
        $desc =~ s/\<[^<>]*\>//go;
        print $F "# $desc #\n" if $c->[0] eq "0";

    }
    close $F;

    open( $F, '>',"$base/spambox.cfg.defaults" );
    for my $idx (0...$#ConfigArray) {
        my $c = $ConfigArray[$idx];
        next if $c->[0] eq "0";
        print $F "$c->[0]:=$c->[4]\n";
    }
    close $F;
    chmod 0664, "$base/spambox.cfg.defaults";

}
