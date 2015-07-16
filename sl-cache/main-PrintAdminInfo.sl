#line 1 "sub main::PrintAdminInfo"
package main; sub PrintAdminInfo {
    my $text = shift;
    my $lt=localtime(time);
    $text=~s/^AdminUpdate://io;
    $text=~s/^Admininfo://io;
    open(my $PAI,'>>',"$base/notes/admininfo.txt");
    print $PAI "$lt:  $text\n";
    close $PAI;
}
