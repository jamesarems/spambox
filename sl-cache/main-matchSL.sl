#line 1 "sub main::matchSL"
package main; sub matchSL {
    my ($ad,$re,$nolog)=@_;
    my @ad = (ref($ad)) ? @$ad : ($ad);
    d("matchSL - @ad - $re",1);
    return 0 unless $re;
    my $reRE = ${$MakeSLRE{$re}};
    return 0 if $reRE =~ /$neverMatchRE/o;
    my $alllog;
    $alllog = 1 if $allLogRe && grep(/$allLogReRE/,@ad);
    my $ret;
    $ret = matchARRAY($reRE,\@ad);
    if ($alllog or ($slmatchLogging && !$nolog && $ret) ) {
        my $matches = $ret ? "matches $ret": 'does not match';
        mlog( 0, "@ad $matches in $re", 1 );
    }
    return $ret ? 1 : 0;
}
