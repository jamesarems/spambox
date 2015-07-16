#line 1 "sub main::heading"
package main; sub heading {my ($description,$nodeId)=@_[4,5];
my $pagebreak = " style=\"page-break-before: always;\"" ;
$headerTOC .= "<tr style=\"margin-left:3cm;\"><td><b>$description</b></td></tr>\n";
"</div>
<div onmousedown=\"toggleDisp('$nodeId');setAnchor('delete');\" class=\"contentHead\"$pagebreak>
 $description
</div>
<div id=\"$nodeId\">\n";
}
