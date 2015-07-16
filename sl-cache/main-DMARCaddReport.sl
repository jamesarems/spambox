#line 1 "sub main::DMARCaddReport"
package main; sub DMARCaddReport {
    my $fh = shift;
    my $this = $Con{$fh};
    my $size = $this->{dmarc}->{ruaSize} || 0;
    my $pol = $this->{dmarc}->{domain} . ' ' . $this->{dmarc}->{toDomain};
    my $polrec;
    if (! exists $DMARCpol{$pol}) {
        my $time = time;
        $polrec = $time . ' ' . ($time + $this->{dmarc}->{ri}) . ' ' . $this->{dmarc}->{rua} . ' ' . $size . ' ';
        $polrec .= " <policy_published>\n";
        for (qw(domain adkim aspf p sp pct rf ri fo)) {
            $polrec .= "  <$_>$this->{dmarc}->{$_}</$_>\n" if $this->{dmarc}->{$_};
        }
        $polrec .= " </policy_published>\n";
        $DMARCpol{$pol} = $polrec;
        mlog($fh,"info: added [DMARC] policy : $pol : $polrec") if $SPFLog >= 2;
        mlog($fh,"info: added [DMARC] policy : $pol") if $SPFLog == 1;
    }
    my $key = <<EOT;
$pol
 <record>
  <row>
   <source_ip>$this->{dmarc}->{source_ip}</source_ip>
   XxxCOUNTyyY
   <policy_evaluated>
    <disposition>$this->{dmarc}->{p}</disposition>
    <dkim>$this->{dmarc}->{policy_evaluated}->{dkim}</dkim>
    <spf>$this->{dmarc}->{policy_evaluated}->{spf}</spf>
EOT
    $key .= <<EOT if $this->{dmarc}->{policy_evaluated}->{reason};
    <reason>$this->{dmarc}->{policy_evaluated}->{reason}</reason>
EOT
    $key .= <<EOT;
   </policy_evaluated>
  </row>
  <identifiers>
   <header_from>$this->{dmarc}->{dom}</header_from>
  </identifiers>
  <auth_results>
   <dkim>
    <domain>$this->{dmarc}->{dom}</domain>
    <result>$this->{dmarc}->{auth_results}->{dkim}</result>
   </dkim>
   <spf>
    <domain>$this->{dmarc}->{mfd}</domain>
    <result>$this->{dmarc}->{auth_results}->{spf}</result>
   </spf>
  </auth_results>
 </record>
EOT
    $DMARCrec{$key}++;
    mlog($fh,"info: added [DMARC] record : $key") if $SPFLog >= 2;
    mlog($fh,"info: added [DMARC] record : $pol : $this->{dmarc}->{source_ip}") if $SPFLog == 1;
    return;
}
