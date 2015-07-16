#line 1 "sub main::remoteSupport"
package main; sub remoteSupport {
    my $addr = lc($qs{ip});
    $addr =~ s/^\s+//o;
    $addr =~ s/\s+$//o;
    my $wrongaddr;
    if ($addr !~ /^$IPRe$/o) {
        $wrongaddr = '<br /><span class="negative">This is not a valid IP address or a resolvable hostname!</span><br />' ;
    }
    if ($wrongaddr && $addr =~ /^$HostRe$/o) {
        my $ta = $addr;
        $addr = join(' ' ,&getRRA($ta,''));
        if ($addr =~ /($IPv4Re)/o) {
            $addr = $1;
        } elsif ($addr =~ /($IPv6Re)/o) {
            $addr = $1;
        } else {
            $addr = undef;
        }
        eval {$addr = inet_ntoa( scalar( gethostbyname($ta) ) );} unless $addr;
        if ($addr =~ /^$IPRe$/o ) {
            $wrongaddr = undef;
        } else {
            $addr = $ta;
        }
    }
    $addr = $RemoteSupportEnabled if (! $addr && ! exists $qs{Submit} && $RemoteSupportEnabled);
    if ($addr && $qs{Submit} eq 'ON') {
        $RemoteSupportEnabled = $addr;
        mlog(0,"admininfo: Remote Support is now enabled for connections from IP: $addr - by $WebIP{$ActWebSess}->{user} from $WebIP{$ActWebSess}->{ip}");
    } elsif ($addr && ! exists $qs{Submit}) {
        $RemoteSupportEnabled = $addr;
        $wrongaddr = undef;
    } else {
        $RemoteSupportEnabled = undef;
        mlog(0,"admininfo: Remote Support is now disabled - by $WebIP{$ActWebSess}->{user} from $WebIP{$ActWebSess}->{ip}");
    }
    my $stat = $RemoteSupportEnabled ? 'OFF' : 'ON' ;
    my $slo = $RemoteSupportEnabled ? "Remote Support is still enable for connection from IP $addr": 'Remote Support is still disabled';
    $wrongaddr = undef unless $addr;

    return <<EOT;
$headerHTTP

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <meta http-equiv="content-type" content="application/xhtml+xml; charset=utf-8" />
  <title>$currentPage ASSP Remote Support ($myName)</title>
  <link rel=\"stylesheet\" href=\"get?file=images/editor.css\" type=\"text/css\" />
</head>
<body onmouseover="this.focus();" ondblclick="this.select();">
<h2>start/stop allow Remote Support GUI access from IP/host</h2><hr>
    <div class="content">
      <form name="edit" id="edit" action="" method="post" autocomplete="off">
        <h3>allow Remote Support from this IP-address or hostname</h3>
        <input name="ip" size="20" autocomplete="off" value="$addr" "/>
        $wrongaddr
        <br /><hr>
        <input type="submit" name="Submit" value="$stat" />&nbsp;&nbsp;&nbsp;&nbsp;
        <input type="button" value="Close" onclick="javascript:window.close();"/>
        <hr>
        $slo
        <hr><br />
        To start accepting remote support connections, type the IP or the hostname you've got from the support stuff
        into the field and click ON.<br />
        To stop accepting remote support connections click OFF<br /><br />
        NOTICE: the remote support remains active, if you close this windows in active state! To stop the remote support
        open this windows again and click OFF.<br /><br />
        The remote support will only work, if assp is connected to the Internet (directly or NAT). Tell the support stuff
        the public IP address or hostname (eg. the MX) and the SMTP port, assp is listening to. The support stuff will also need
        login data to access the GUI and the information if SSL is required (or not) to access the GUI.<br /><br />
        Keep in mind, that nobody else than root will be able to login to the GUI, if you are still logged on using the root account!<br /><br />
        ASSP will write a warning to the maillog.txt every 15 minutes, if the remote support is enabled.<br /><br />
        ALSO NOTICE: you will not be able to receive any email from the remote support IP address, while the remote
        support is enabled!
      </form>
    </div>
</body>
</html>

EOT

}
