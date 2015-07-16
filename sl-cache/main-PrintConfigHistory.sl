#line 1 "sub main::PrintConfigHistory"
package main; sub PrintConfigHistory {
    my $text = shift;
    my $lt=localtime(time);
    $text=~s/^AdminUpdate://io;
    $text=~s/^Admininfo://io;
    open(my $PCH,'>>',"$base/notes/confighistory.txt");
    print $PCH "$lt:  $text\n";
    close $PCH;
}
