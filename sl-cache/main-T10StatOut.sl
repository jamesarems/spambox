#line 1 "sub main::T10StatOut"
package main; sub T10StatOut {
    my $t10html = "<div name=\"tohid\"><br /><h2>Top ten blocking statistic</h2><br />";
      $t10html .= "only entries that were stated in the last 25 hours are shown<br />";
    my $t10text = "\r\nTop ten blocking statistic\r\n";
      $t10text .= "only entries that were stated in the last 25 hours are shown\r\n";
       $t10text .=    "----------------------------------------------------------------------\r\n";
    my @list =  (
                    'Top ten blocked domains',   'D',
                    'Top ten blocked IP\'s',     'I',
                    'Top ten blocked senders',   'S',
                    'Top ten blocked recipients','R'
    );

    while (@list) {
        $t10html .= '<br /><table BORDER CELLSPACING=2 CELLPADDING=4 WIDTH="25%" >';
        $t10html .= "<col /><col />\n";
        my $s1 = shift @list;
        $t10html .= '<tr><th colspan="2">'.$s1."</th></tr>\n";
        $t10text .= "\r\n\r\n".$s1.":\r\n";
        my @th = T10StatGet((shift @list),10);
        while (@th) {
            my $s2 = shift @th;
            my $s3 = shift @th;
            $t10html .= '<tr><td>&nbsp;' . $s2 . '&nbsp;</td><td>&nbsp;'. $s3 . "\&nbsp;</td></tr>\n";
            $t10text .= "$s2\t$s3\r\n";
        }
        $t10html .= "</table><br /></div>\n";
        $t10text .= "\r\n";
    }
    return $t10html, $t10text;
}
