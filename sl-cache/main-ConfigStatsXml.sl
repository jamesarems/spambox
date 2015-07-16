#line 1 "sub main::ConfigStatsXml"
package main; sub ConfigStatsXml {

    # must be passed as ref
    my ( $href, $qsref ) = @_;

    my %tots;
    {lock(%Stats) if (is_shared(%Stats));
    &StatAllStats();
    %tots = statsTotals();
    }

    my $statstart2=localtime($AllStats{starttime});
    my $statstart=localtime($Stats{starttime});
    my $uptime=getTimeDiffAsString(time-$Stats{starttime},1);
    my $uptime2=getTimeDiffAsString(time-$AllStats{starttime});
    my $damptime=getTimeDiffAsString($Stats{damptime},1);
    my $damptime2=getTimeDiffAsString($AllStats{damptime});
    my $mpd=sprintf("%.1f",$uptime==0 ? 0 : $tots{msgTotal}/$uptime);
    my $mpd2=sprintf("%.1f",$uptime2==0 ? 0 : $tots{msgTotal2}/$uptime2);
    my $pct=sprintf("%.1f",$tots{msgTotal}-$Stats{locals}==0 ? 0 : 100*$tots{msgRejectedTotal}/($tots{msgTotal}-$Stats{locals}));
    my $pct2=sprintf("%.1f",$tots{msgTotal2}-$AllStats{locals}==0 ? 0 : 100*$tots{msgRejectedTotal2}/($tots{msgTotal2}-$AllStats{locals}));
    my $cpuAvg=sprintf("%.2f\%",(! $Stats{cpuTime} ? 0 : 100*$Stats{cpuBusyTime}/$Stats{cpuTime}));
    my $cpuAvg2=sprintf("%.2f\%",(! $AllStats{cpuTime} ? 0 : 100*$AllStats{cpuBusyTime}/$AllStats{cpuTime}));
    my $currAvgDamp = ($Stats{damping} && $DoDamping) ? sprintf("(%.2f%% avg of accepted connections)",($Stats{damping} / ($Stats{smtpConn} ? $Stats{smtpConn} : 1)) * 100) : '';
    my $allAvgDamp  = ($AllStats{smtpConn} && $DoDamping) ? sprintf("(%.2f%% avg of accepted connections)",($AllStats{damping} / ($AllStats{smtpConn} ? $AllStats{smtpConn} : 1)) * 100) : '';
    my $memory = memoryUsage().'MB';

    my $r = '';
    foreach my $k ( keys %tots ) {
        next unless $k;

        my $s = $k;
        if ( $s =~ tr/2//d ) {
            $r .= "<stat name='$s' type='cumulativetotal'>$tots{$k}</stat>";
        } else {
            $r .= "<stat name='$s' type='currenttotal'>$tots{$k}</stat>";
        }
    }
    foreach my $k ( keys %Stats ) {
        next unless $k;
        $r .= "<stat name='$k' type='currentstat'>$Stats{$k}</stat>";
    }
    foreach my $k ( keys %AllStats ) {
        next unless $k;
        $r .= "<stat name='$k' type='cumulativestat'>$AllStats{$k}</stat>";
    }
    foreach my $k ( keys %ScoreStats ) {
        next unless $k;
        $r .= "<stat name='$k' type='currentscorestat'>$ScoreStats{$k}</stat>";
    }
    foreach my $k ( keys %AllScoreStats ) {
        next unless $k;
        $r .= "<stat name='$k' type='cumulativescorestat'>$AllScoreStats{$k}</stat>";
    }

    <<EOT;
$headerHTTP

<?xml version='1.0' encoding='UTF-8'?>
<stats>
<stat name='statstart' type='currentstat'>$statstart</stat>
<stat name='statstart' type='cumulativestat'>$statstart2</stat>
<stat name='uptime' type='currentstat'>$uptime</stat>
<stat name='uptime' type='cumulativestat'>$uptime2</stat>
<stat name='msgPerDay' type='currentstat'>$mpd</stat>
<stat name='msgPerDay' type='cumulativestat'>$mpd2</stat>
<stat name='pctBlocked' type='currentstat'>$pct</stat>
<stat name='pctBlocked' type='cumulativestat'>$pct2</stat>
<stat name='cpuAvg' type='currentstat'>$cpuAvg</stat>
<stat name='cpuAvg' type='cumulativestat'>$cpuAvg2</stat>
<stat name='memusage' type='currentstat'>$memory</stat>
<stat name='smtpConcurrentSessions' type='currentstat'>$smtpConcurrentSessions</stat>
<stat name='damptime' type='currentstat'>$damptime</stat>
<stat name='damptime' type='cumulativestat'>$damptime2</stat>
<stat name='avgdamped' type='currentstat'>$currAvgDamp</stat>
<stat name='avgdamped' type='cumulativestat'>$allAvgDamp</stat>
$r
</stats>
EOT

}
