#line 1 "sub main::checkFileHashUpdate"
package main; sub checkFileHashUpdate {
    d('checkFileHashUpdate');
    my $ret = 0;
    while (my ($file,$ftime) = each %FileHashUpdateTime) {
       next if $ftime == ftime($file);
       &LoadHash($FileHashUpdateHash{"$file"},$file,0);
       $ret = 1;
    }
    while (my ($file,$ftime) = each %FileHashUpdateTimeUS) {
       next if $ftime == ftime($file);
       &LoadHash($FileHashUpdateHashUS{"$file"},$file,0);
       $ret = 1;
    }
    return $ret;
}
