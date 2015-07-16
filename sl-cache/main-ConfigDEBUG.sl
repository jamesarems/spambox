#line 1 "sub main::ConfigDEBUG"
package main; sub ConfigDEBUG {my ($name, $old, $new, $init)=@_;
    close $DEBUG if $debug;
    $debug=$new;
    if($debug) {
        my $file = "$base/debug/".time.".dbg";
        open($DEBUG, '>',"$file");
        binmode($DEBUG);
        $DEBUG->autoflush;
        print $DEBUG $UTF8BOM;
        print $DEBUG "running SPAMBOX version: $main::MAINVERSION\n\n";
        mlog(0,"info: starting general debug mode to file $file");
    }
    mlog(0,"AdminUpdate: general debug changed to '$new' from '$old' ");
    return '';
}
