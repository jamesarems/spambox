#line 1 "sub main::ConfigShowError"
package main; sub ConfigShowError {
    my ($red, $msg, $noprepend, $noipinfo , $noS) = @_;
    return unless $msg;
    mlog(0, $msg, $noprepend, $noipinfo , $noS);
    my ($prsp,$posp);
    if ($red) {
        $prsp = '<span class="negative">';
        $prsp = '</span>';
    }
    $msg =~ s/[^:]+:\s*//o;
    return "$prsp$msg$prsp<br />\n";
}
