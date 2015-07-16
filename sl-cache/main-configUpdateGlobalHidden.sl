#line 1 "sub main::configUpdateGlobalHidden"
package main; sub configUpdateGlobalHidden {
    my ($name, $old, $new, $init)=@_;
    $$name = $old;
    $Config{$name}=$old;
    if ($old eq '') {
       return '*** deleted ***';
    } else {
       return '';
    }
}
