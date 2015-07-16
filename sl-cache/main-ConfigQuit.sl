#line 1 "sub main::ConfigQuit"
package main; sub ConfigQuit {
 my $fh=shift;
 mlog(0,'quit requested from admin interface');
 &NoLoopSyswrite($fh, "HTTP/1.1 200 OK
Content-type: text/html


<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body><h1>SPAMBOX Terminated.</h1>
</body></html>
",0);
 &downSPAMBOX('quit requested from admin interface');
 exit 2;
}
