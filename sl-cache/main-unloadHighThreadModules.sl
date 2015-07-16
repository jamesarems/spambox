#line 1 "sub main::unloadHighThreadModules"
package main; sub unloadHighThreadModules {
    unloadNameSpace 'Win32::Daemon';
    unloadNameSpace 'Win32::API::OutputDebugString';
    unloadNameSpace 'Sys::Syslog';
    unloadNameSpace 'Thread::State';
    unloadNameSpace 'Convert::TNEF';
    unloadNameSpace 'Mail::SRS';
    unloadNameSpace 'NetSNMP::agent';
    unloadNameSpace 'NetSNMP::ASN';
    unloadNameSpace 'NetSNMP::default_store';
    unloadNameSpace 'NetSNMP::agent::default_store';
    unloadNameSpace 'File::ReadBackwards';
    unloadNameSpace 'Tie::RDBM' unless $useTieRDBM;

    %lngmsg =();
    undef %lngmsg;
    %lngmsghint =();
    undef %lngmsghint;
    undef $kudos;
    undef $footers;
    undef $headers;
    undef $headerTOC;
    undef $headerGlosar;
    %glosarIndex = ();
    undef $headerDTDStrict;
    undef $headerDTDTransitional;
    undef $headerHTTP;
    undef $crashHMM;
}
