#line 1 "sub main::GetFile"
package main; sub GetFile{
 my $fil=$qs{file};
 if ($fil=~/\.\./o) {
  mlog(0,"file path not allowed while getting file '$fil'");
  return <<EOT;
HTTP/1.1 403 Forbidden
Content-type: text/html

<html><body><h1>Forbidden</h1>
</body></html>
EOT
 }

 if ($fil !~ /^\Q$base\E/io) {
  $fil="$base/$fil";
 }
 d("web: get file: $fil");

 my $certsRe = quotemeta($SSLCertFile).'|'.quotemeta($SSLKeyFile).'|'.quotemeta($SSLCaFile);
 if ($WebIP{$ActWebSess}->{user} ne 'root' && $fil=~/^(?:$certsRe)$/i) {
  mlog(0,"error: user $WebIP{$ActWebSess}->{user} has tried to download security file '$fil'");
  return <<EOT;
HTTP/1.1 403 Forbidden
Content-type: text/html

<html><body><h1>Forbidden</h1>
</body></html>
EOT
 }

 if ($eF->( $fil )) {
   my $mtime;
   if (defined ($mtime=$head{'if-modified-since'})) {
    if (defined ($mtime=HTTPStrToTime($mtime))) {
     if ($mtime >= ftime($fil)) {
      return "HTTP/1.1 304 Not Modified\n\r\n\r";
     }
    }
   }
   my $s;
   if($open->(my $GF,'<',$fil)) {
    $GF->binmode;
    $GF->read($s,[$stat->($fil)]->[7]);
    $GF->close;
    my %mimeTypes=(
     'log|txt|pl' => 'text/plain',
     'htm|html' => 'text/html',
     'css' => 'text/css',
     'bmp' => 'image/bmp',
     'gif' => 'image/gif',
     'jpg|jpeg' => 'image/jpeg',
     'png' => 'image/png',
     'ico' => 'image/ico',
     'zip' => 'application/zip',
     '7z' => 'application/zip',
     'sh' => 'application/x-sh',
     'gz|gzip' => 'application/x-gzip',
     'exe' => 'application/octet-stream',
     'js' => 'application/x-javascript'
    );
    my $ct='text/plain'; # default content-type
    foreach my $key (keys %mimeTypes) {
     $ct=$mimeTypes{$key} if $fil=~/\.($key)$/i;
    }
    $mtime=ftime($fil);
    $mtime=gmtime($mtime);
    $mtime=~s/(...) (...) +(\d+) (........) (....)/$1, $3 $2 $5 $4 GMT/o;
    return <<EOT;
HTTP/1.1 200 OK
Content-type: $ct
Last-Modified: $mtime

$s
EOT
    }
   }
   return <<EOT;
HTTP/1.1 404 Not Found
Content-type: text/html

<html><body><h1>Not found</h1>
</body></html>
EOT

}
