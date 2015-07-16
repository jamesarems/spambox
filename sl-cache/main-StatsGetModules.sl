#line 1 "sub main::StatsGetModules"
package main; sub StatsGetModules {
 my  @modArray;
 my  $modules = '<tr>
                   <td class="statsOptionTitle"><font color=blue>Module Name</font>
                   </td>
                   <td class="statsOptionValue" colspan="2"><font color=blue>Module Version</font>
                   </td>
                   <td class="statsOptionValue" colspan="1"><font color=blue>Module Status</font>
                   </td>
                   <td class="statsOptionValueC" colspan="1"><font color=blue>Download</font>
                   </td>
                  </tr>';
     $modules .= '<tr>
                   <td class="statsOptionTitle"><font color=blue><a href="javascript:void(0);" onclick="javascript:popFileEditor(\'moduleLoadErrors.txt\',8);">show</a> module load errors</font>
                   </td>
                   <td class="statsOptionValue" colspan="2"><font color=blue>installed  /  required(recommended)</font>
                   </td>
                   <td class="statsOptionValue" colspan="1"><font color=blue>&nbsp;</font>
                   </td>
                   <td class="statsOptionValueC" colspan="1"><font color=blue>&nbsp;</font>
                   </td>
                  </tr>';
 foreach (sort keys %ModuleList) {
     my ($inst,$requ) = split(/\//o, $ModuleList{$_});
     my $ti = $inst;
     my $tr = $requ;
     $ti =~ s/[0 ]+$//o;
     $tr =~ s/[0 ]+$//o;
     $ti =~ s/^[0 ]+//o;
     $tr =~ s/^[0 ]+//o;
     $ti =~ s/_.*$//o;
     $tr =~ s/_.*$//o;
     if ($ti && $ti =~ /([\d\._]+)/o) {
         if ($1 lt $tr) {
             $inst = '<font color=red>'.$inst.'</font>';
             $requ = '<font color=red>'.$requ.'</font>';
         }
     } else {
             my $modvar = "use$_";
             $modvar =~ s/:://go;
             $inst = $$modvar ? 'not installed' : defined $$modvar ? "disabled by <a href=\"./#$modvar\">Module Setup</a>" : '';
             $inst = '<font color=red>'.$inst.'</font>';
             $requ = '<font color=red>'.$requ.'</font>';
     }
     my $url = 'http://search.cpan.org/search?query='.$_;
     $url = 'http://www.oracle.com/technology/products/berkeley-db/' if ($_ eq 'BerkeleyDB_DBEngine');
     $url = 'http://assp.cvs.sourceforge.net/viewvc/assp/assp2/lib/' if ($_ eq 'AsspSelfLoader');
     $url = 'http://assp.cvs.sourceforge.net/viewvc/assp/assp2/lib/' if ($_ eq 'ASSP_WordStem');
     $url = 'http://assp.cvs.sourceforge.net/viewvc/assp/assp2/filecommander/' if ($_ eq 'ASSP_FC');
     $url = 'http://assp.cvs.sourceforge.net/viewvc/assp/assp2/lib/' if ($_ eq 'ASSP_SVG');
     $url = 'http://assp.cvs.sourceforge.net/viewvc/assp/assp2/Plugins/' if ($_ =~ /^Plugins/o);
     my $prov = 'CPAN';
     $prov = 'oracle' if ($_ eq 'BerkeleyDB_DBEngine');
     $prov = 'sourceforge' if ($_ =~ /^Plugins/o or $_ eq 'AsspSelfLoader' or $_ eq 'ASSP_WordStem' or $_ eq 'ASSP_FC' or $_ eq 'ASSP_SVG');
     my $stat = $ModuleStat{$_} ? $ModuleStat{$_} : 'enabled';
     if ($_ eq 'File::Scan::ClamAV' && $CanUseAvClamd && ! $AvailAvClamd) {
         $stat = 'ClamAvDaemon is down';
     }
     $stat = '<font color=red>'.$stat.'</font>' if $stat ne 'enabled';
     if($_ eq 'Sys::Syslog' && $^O eq 'MSWin32') {
         $inst = 'not supported by operating system';
          push @modArray , [$_,$inst,$requ,$stat,$url];
          next;
     }
     if($_ =~ /^Win32::/io && $^O ne 'MSWin32') {
         $inst = 'not supported by operating system';
          push @modArray , [$_,$inst,$requ,$stat,$url];
          next;
     }
     push @modArray , [$_,$inst,$requ,$stat,$url];
     $modules .= '<tr>
                   <td class="statsOptionTitle">'. $_ .
                  '</td>
                   <td class="statsOptionValue" colspan="2">' . $inst . '  /  ' . $requ.
                  '</td>
                   <td class="statsOptionValue" colspan="1">' . $stat .
                  '</td>
                   <td class="statsOptionValueC" colspan="1">
                     <a href="'.$url.'" rel="external">'.$prov.'</a>
                   </td>
                  </tr>';
 }
 return $modules,@modArray;
}
