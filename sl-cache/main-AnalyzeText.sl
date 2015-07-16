#line 1 "sub main::AnalyzeText"
package main; sub AnalyzeText {
    my $fh = shift;
    my $this = $Con{$fh};
    my $mail = $this->{header};
    $mail =~ s/^.*?\n[\r\n\s]+//so;
    my %sqs = %qs;
    %qs = ();
    $qs{mail} = $mail;
    $qs{return} = 1;
    $qs{mailfrom} = $this->{mailfrom} if $this->{mailfrom};
    $qs{classification} = $this->{classification} if $this->{classification};
    my $res = &ConfigAnalyze();
    my $sub = $qs{sub};
    my $style;
    my $fil = "$base/images/assp.css";
    if($open->(my $GF,'<',$fil)) {
        $GF->binmode;
        $GF->read($style,[$stat->($fil)]->[7]);
        $GF->close;
    }
    $this->{reporthint} = "<b>$this->{reporthint}</b>
<hr><br /><br />" if $this->{reporthint};

    $this->{report} .= <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
  "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>SPAMBOX Analyze from $myName</title>
<style type="text/css">
$style
.content {
	margin: 5px 0 0 0;
}
</style>
</head>
<body>
<div class="content">
<br /><hr><br />
<h2>SPAMBOX Mail Analyzer on $myName</h2>
<hr><br /><br />
$this->{reporthint}
$res
</div>
</body>
</head>
</html>

EOT
    %qs = %sqs;
    return $sub;
}
