#line 1 "sub main::printallCon"
package main; sub printallCon {
    my ($fh,$exept) = @_;
    my $this = $Con{$fh};
    return unless $this;
    return unless scalar(keys %$this);
    my $friend = $Con{$this->{friend}};
    my $c = 1;
    while (-s "$base/debug/con$c.txt") {$c++}
    my $file = "$base/debug/con$c.txt";
    my $OUT;
    open $OUT, '>',"$file";
    binmode $OUT;
    print $OUT "SPAMBOX version: $MAINVERSION\n\n";
    print $OUT "Worker $WorkerNumber - Connection Data ----\n\n";
    print $OUT "exception detected $exept\n" if $exept;
    print $OUT "last debug step was: $lastd{$WorkerNumber}\n";
    print $OUT "last sigoff was    : $lastsigoff{$WorkerNumber}\n";
    print $OUT "last sigon  was    : $lastsigon{$WorkerNumber}\n\n";
    print $OUT "this --------------------------------------\n";
    while (my ($k,$v) = each %$this) {
       print $OUT "this->$k = $v\n";
       eval {
           if (ref($v) eq 'HASH') {
               print $OUT "values of HASH this->$k :\n";
               print $OUT "this->$k = $_ => ${$v}{$_}\n" foreach (keys %{$v});
           }
           if (ref($v) eq 'ARRAY') {
               print $OUT "values of ARRAY this->$k :\n";
               print $OUT "this->$k = $_\n" for (@{$v});
           }
       }
    }
    if ($friend) {
        print $OUT "\nfriend --------------------------------------\n";
        while (my ($k,$v) = each %$friend) {
           print $OUT "friend->$k = $v\n";
           eval {
               if (ref($v) eq 'HASH') {
                   print $OUT "values of HASH friend->$k :\n";
                   print $OUT "friend->$k = $_ => ${$v}{$_}\n" foreach (keys %{$v});
               }
               if (ref($v) eq 'ARRAY') {
                   print $OUT "values of ARRAY friend->$k :\n";
                   print $OUT "friend->$k = $_\n" for (@{$v});
               }
           }
        }
    }
    close $OUT;
    mlog($fh,"info: wrote all current available connection data to file $base/debug/con$c.txt");
}
