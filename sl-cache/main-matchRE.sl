#line 1 "sub main::matchRE"
package main; sub matchRE {
    my ($ad,$re,$nolog)=@_;
    my @ad = (ref($ad)) ? @$ad : ($ad);
    $lastREmatch = '';
    d("matchRE - @ad - $re",1);
    return 0 unless $re;
    if (! exists $main::{$re.'RE'}) {
        my ($package, $file, $line) = caller;
        mlog(0,'error: '.$re.'RE is not defined in matchRE - called from: $package, $file, $line');
        return 0;
    }
    return 0 unless ${$re.'RE'};
    my $reRE = ${$re.'RE'};
    return 0 if $reRE =~ /$neverMatchRE/o;
    my $alllog;
    $alllog = 1 if $allLogRe && grep(/$allLogReRE/,@ad );
    $lastREmatch = matchARRAY($reRE,\@ad);
    if ($alllog or ($regexLogging && !$nolog && $lastREmatch) ) {
        my $matches = $lastREmatch ? "matches $lastREmatch": 'does not match';
        mlog( 0, "@ad $matches in $re", 1 );
    }
    return $lastREmatch ? 1 : 0;
}
