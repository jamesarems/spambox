#line 1 "sub main::formatMethod"
package main; sub formatMethod {
    my $res;
    if ($_[2]==0) {
        $res=int($_[0]/$_[1]);
        $_[0]-=$res*$_[1]; # modulus on floats
    } elsif ($_[2]==1) {
        if ($_[0]>=$_[1]) {
            $res=sprintf("%.1f",$_[0]/$_[1]);
            $_[0]=0;
        }
    }
    return $res;
}
