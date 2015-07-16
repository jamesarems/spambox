#line 1 "sub main::configUpdateDKIMConf"
package main; sub configUpdateDKIMConf {
    my ( $name, $old, $new, $init ) = @_;

    my $file = $new;
    $file =~ /^\s*file:\s*(.+)\s*$/oi;
    $file = "$base/$1";
    my $f;
    my $domain;
    my $selector;
    my @domains;
    my %dkim = ();
    ${$name} = $new unless $WorkerNumber;

    return unless &fileUpdated($file, $name);

    my $mtime = ftime($file);
    $FileUpdate{"$file$name"} = $mtime if $mtime;

    return unless ( open $f,'<', "$file" );
    while (<$f>) {
        next if /^\s*#/o;
        if (/^\s*<([^\/]+)>/o) {
            $selector = $1 if(! $selector && $domain);
            $domain = lc($1) unless ($domain);
        } elsif ( $selector && /^\s*<\/$selector>/i ) {
            $selector = '';
        } elsif ( $domain && /^\s*<\/$domain>/i ) {
            $domain = '';
            $selector = '';
        } elsif ($selector) {
            my ($key,$value) = split(/=/o,$_);
            $key =~ s/^\s*//o;
            $key =~ s/\s*$//o;
            $value =~ s/\s*$//go;
            $value =~ s/^\s*//go;
            next unless $key;
            next unless $value;
            $dkim{$domain}->{$selector}{$key} = $value;
        }
    }
    close $f;
    my ($h,$d) = &DKIMcfgvalid(%dkim);
    @domains = ();
    @domains = @{$d};
    %DKIMInfo = ();
    %DKIMInfo = %{$h};
    push @domains, " - no entries found !!!" unless @domains;
    my $tlit = $init ? '' : 'AdminUpdate: ';
    mlog(0,$tlit."DKIM configuration (re)loaded from file $file for domain(s):@domains") if $WorkerNumber == 0 && $WorkerName ne 'startup';
}
