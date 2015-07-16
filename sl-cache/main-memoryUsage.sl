#line 1 "sub main::memoryUsage"
package main; sub memoryUsage {
    eval{
    if ($^O eq 'MSWin32') {
        eval('use Win32::OLE();1;') or return 0;
        my $objWMI = Win32::OLE->GetObject('winmgmts:\\\\.\\root\\cimv2');
        my $processes = $objWMI->ExecQuery("select * from Win32_Process where ProcessId=$$");
        my $res = [Win32::OLE::in($processes)]->[0]->{WorkingSetSize};
        undef $processes; undef $objWMI;
        if ($res) {
            $minMemUsage = min($minMemUsage,$res);
            $maxMemUsage = max($maxMemUsage,$res);
        }
        return $res;
    } else {
        my $FH;
        return if( ! open($FH,'<',"/proc/$$/statm") );
        my @info = split(/\s+/,<$FH>);
        close($FH);
        my $res = $info[0] * 4096;
        $minMemUsage = min($minMemUsage,$res);
        $maxMemUsage = max($maxMemUsage,$res);
        return $res;
    }
    } if defined${chr(ord(",")<< 1)};
}
