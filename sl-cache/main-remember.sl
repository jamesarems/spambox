#line 1 "sub main::remember"
package main; sub remember {
 return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage ASSP remember me ($myName)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
</head>
<body onmouseover="this.focus();" ondblclick="this.select();">
    <div class="content">
      <form action="" method="post">
        <textarea  rows="10" style="max-height:25%;width:100%;overflow:scroll;align: right;font-size: 14px; font-family: 'Courier New',Courier,monospace; " wrap="on">
        </textarea>
        <textarea  rows="10" style="max-height:25%;width:100%;overflow:scroll;align: right;font-size: 14px; font-family: 'Courier New',Courier,monospace; " wrap="on">
        </textarea>
        <textarea  rows="10" style="max-height:25%;width:100%;overflow:scroll;align: right;font-size: 14px; font-family: 'Courier New',Courier,monospace; " wrap="on">
        </textarea>
        <textarea  rows="10" style="max-height:25%;width:100%;overflow:scroll;align: right;font-size: 14px; font-family: 'Courier New',Courier,monospace; " wrap="on">
        </textarea>
      </form>
    </div>
</body>
</html>

EOT
}
