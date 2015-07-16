#line 1 "sub main::top10stats"
package main; sub top10stats {
    my ($t10html, $t10text) = &T10StatOut();
    my $ire = qr/^(?:$IPRe|[\d\.]+)$/o;
    unless ((&canUserDo($WebIP{$ActWebSess}->{user},'action','addraction') && $t10html =~ s/((?:$EmailAdrRe\@)?$EmailDomainRe)/my$e=$1;($e!~$ire)?"<a href=\"\/addraction?address=$e\" target=\"_blank\" title=\"take an action via web on address $e\">$e<\/a>":$e/goe))
        {
            ((&canUserDo($WebIP{$ActWebSess}->{user},'action','ipaction') && $t10html =~ s/($IPRe)/my$e=$1;($e!~$IPprivate)?"<a href=\"\/ipaction?ip=$e\" target=\"_blank\" title=\"take an action via web on ip $e\">$e<\/a>":$e;/goe));
        }
    return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage ASSP Top ten statistic ($myName)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
</head>
<body>
    <div class="content">
        $t10html
    </div>
</body>
</html>

EOT
}
