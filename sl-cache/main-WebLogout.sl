#line 1 "sub main::WebLogout"
package main; sub WebLogout {
    my $fh = shift;
    my $ip=$fh->peerhost();
    my $port=$fh->peerport();
    mlog(0,"logout from admin interface requested for user '$WebIP{$ActWebSess}->{user}' at '$ip'");
    my $user = $WebIP{$ActWebSess}->{user};
    %{$WebIP{$ActWebSess}->{perm}} = ();
    mlog(0,"terminated WEB session $ActWebSess for user '$WebIP{$ActWebSess}->{user}' at '$ip'");
    delete $WebIP{$ActWebSess};
    my $isrootLoggedOn;
    foreach (keys %WebIP) {
        next if $_ eq 'SNMP';
        if ($WebIP{$_}->{user} eq 'root') {
            if ($WebIP{$_}->{rootlogin} < time - 900 || $WebIP{$_}->{ip} eq $ip) {
                mlog(0,"terminated WEB session $_ for user 'root' at '$ip'");
                %{$WebIP{$_}->{perm}} = ();
                delete $WebIP{$_};
            } else {
                $isrootLoggedOn = $WebIP{$_}->{rootlogin};
                my $t = time - $WebIP{$_}->{rootlogin};
                mlog(0,"info: user root is still logged on from IP '$WebIP{$_}->{ip}' with session '$_' since $t seconds");
            }
        } elsif ($WebIP{$_}->{user} eq $user && $WebIP{$_}->{ip} eq $ip) {
            mlog(0,"terminated WEB session $_ for user '$WebIP{$_}->{user}' at '$ip'") if $user;
            %{$WebIP{$_}->{perm}} = ();
            delete $WebIP{$_};
        }
    }
    $rootlogin = $isrootLoggedOn;
    my $realm = time;
        &NoLoopSyswrite($fh, "HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm=\"logged out ASSP session $realm - please click cancel and close the browser\"
Content-type: text/html

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\"><body>
<script type=\"text/javascript\">
<!--
try {
  if (document.all) {
    document.execCommand(\"ClearAuthenticationCache\");
  } else {
    var mydom = window.location.host;
    var myprot = window.location.protocol;
    window.location.href = myprot + '//loggedout:loggedout\@' + mydom + '/logout';
  }
} catch(e) {
alert(\"It was not possible to clear your credentials from browser cache. Please, close your browser to ensure that you are completely logout of system.\");
self.close();
}
// -->
</script>
<h1>Logout from ASSP completed.</h1><br /><br />please close the browser
<script type=\"text/javascript\">
<!--
self.close();
// -->
</script>
</body></html>",0);


    WebDone($fh);
    %qs = ();
    %ManagePerm = ();
    %ManageActions = ();
    %ManageAdminUser = ();
    $ActWebSess = undef;
}
