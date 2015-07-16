#line 1 "sub main::ConfigChangeIPv6"
package main; sub ConfigChangeIPv6 {my ($name, $old, $new, $init)=@_;
    mlog( 0, "AdminUpdate: $name changed from '$old' to '$new'" ) unless $init || $new eq $old;
    $Config{$name} = ${$name} = $new;
    return '' if $init || $new eq $old;
    
    if ($new) {
        if ($SysIOSocketINET6 == 0) {
            $CanUseIOSocketINET6 = $AvailIOSocketINET6 = 0;
            mlog(0,"error: IPv6 is not supported by your system");
            return "<br />*** IPv6 is not supported by your system ***<script type=\"text/javascript\">alert(\'IPv6 is not supported by your system\');</script>";
        }
        if (! $useIOSocketINET6) {
            $useIOSocketINET6 = $Config{useIOSocketINET6} = 1;
            mlog(0,"AdminUpdate: useIOSocketINET6 changed from '' to '1'");
        }
	    $CanUseIOSocketINET6 = $AvailIOSocketINET6 = eval("use IO::Socket::INET6; 1");
        my $error = ($CanUseIOSocketINET6) ? '' : $@;
        if ($CanUseIOSocketINET6) {
            if ($SysIOSocketINET6 == -1) {
                $CanUseIOSocketINET6 = $AvailIOSocketINET6 =
                  eval {
                      my $sock = IO::Socket::INET6->new(Domain => AF_INET6, Listen => 1, LocalAddr => '[::]', LocalPort => $IPv6TestPort);
                      if ($sock) {
                          close($sock);
                          $SysIOSocketINET6 = 1;
                          1;
                      } else {
                          $AvailIOSocketINET6 = $SysIOSocketINET6 = 0;
                          0;
                      }
                  };
            }
            if ($CanUseIOSocketINET6) {
                if ($CanUseIOSocketSSL) {
                    eval('no IO::Socket::SSL; use IO::Socket::SSL;');
                }

                if ($WorkerNumber == 0) {
                    configChangeProxy('ProxyConf','',$Config{ProxyConf},'Initializing') if $ProxyConf;
                    ConfigChangeRelayPort('relayPort','',$Config{relayPort},'Initializing') if $relayPort;
                    ConfigChangeMailPort('listenPort','',$Config{listenPort},'Initializing') if $listenPort;
                    ConfigChangeMailPort2('listenPort2','',$Config{listenPort2},'Initializing') if $listenPort2;
                    ConfigChangeMailPortSSL('listenPortSSL','',$Config{listenPortSSL},'Initializing') if $listenPortSSL;

                    ConfigChangeStatPort('webStatPort','',$Config{webStatPort},'Initializing') if $webStatPort;
                    ConfigChangeAdminPort('webAdminPort','',$Config{webAdminPort},'Initializing') if $webAdminPort;
                }
                ConfigChangeTLSPorts('NoTLSlistenPorts','',$Config{NoTLSlistenPorts},'Initializing') if $NoTLSlistenPorts;
                ConfigChangeTLSPorts('TLStoProxyListenPorts','',$Config{TLStoProxyListenPorts},'Initializing') if $TLStoProxyListenPorts;

                mlog(0,"IPv6 support is now enabled");
                return 'IPv6 support is now enabled';
            } else {
                mlog(0,"error: IPv6 is not supported by your system");
                return "<br />*** IPv6 is not supported by your system ***<script type=\"text/javascript\">alert(\'IPv6 is not supported by your system\');</script>";
            }
        }
        mlog(0,"error: unable to start IPv6 support - $error");
        return "<br />*** unable to start IPv6 support ***<script type=\"text/javascript\">alert(\'unable to start IPv6 support\');</script>";
    } else {
        $CanUseIOSocketINET6 = $AvailIOSocketINET6 = 0;
        eval("no IO::Socket::INET6; use IO::Socket::INET;");
        eval("no IO::Socket::SSL; use IO::Socket::SSL 'inet4';") if ($CanUseIOSocketSSL);  # to correct @ISA

        if ($WorkerNumber == 0) {
            configChangeProxy('ProxyConf','',$Config{ProxyConf},'Initializing') if $ProxyConf;
            ConfigChangeRelayPort('relayPort','',$Config{relayPort},'Initializing') if $relayPort;
            ConfigChangeMailPort('listenPort','',$Config{listenPort},'Initializing') if $listenPort;
            ConfigChangeMailPort2('listenPort2','',$Config{listenPort2},'Initializing') if $listenPort2;
            ConfigChangeMailPortSSL('listenPortSSL','',$Config{listenPortSSL},'Initializing') if $listenPortSSL;

            ConfigChangeStatPort('webStatPort','',$Config{webStatPort},'Initializing') if $webStatPort;
            ConfigChangeAdminPort('webAdminPort','',$Config{webAdminPort},'Initializing') if $webAdminPort;
        }
        ConfigChangeTLSPorts('NoTLSlistenPorts','',$Config{NoTLSlistenPorts},'Initializing') if $NoTLSlistenPorts;
        ConfigChangeTLSPorts('TLStoProxyListenPorts','',$Config{TLStoProxyListenPorts},'Initializing') if $TLStoProxyListenPorts;

        mlog(0,"IPv6 support is now disabled");
        return 'IPv6 support is now disabled';
    }
}
