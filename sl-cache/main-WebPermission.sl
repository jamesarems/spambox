#line 1 "sub main::WebPermission"
package main; sub WebPermission {
    d('WebPermission - ' . $WebIP{$ActWebSess}->{user});
    my $text = shift;

    return unless $WebIP{$ActWebSess}->{user};
    return if ($WebIP{$ActWebSess}->{user} eq 'root');
    if (! &canUserDo($WebIP{$ActWebSess}->{user},'action','edit')) {
        $$text =~ s/javascript:popFileEditor\(.+?\);/javascript:alert\('access denied'\);/go;
        $$text =~ s/return popFileEditor\(.+?\)/javascript:alert\('access denied'\)/go;
    }

    foreach my $act (
        'lists',
        'recprepl',
        'maillog',
        'analyze',
        'infostats',
        'resetcurrentstats',
        'resetallstats',
        'statusassp',
        'shutdown_list',
        'shutdown',
        'shutdown_frame',
        'donations',
        'pwd',
        'reload',
        'quit',
        'save',
        'editinternals',
        'syncedit',
        'SNMPAPI',
        'addraction',
        'ipaction',
        'statgraph',
        'confgraph',
        'fc',
        'remotesupport'
    )
    {
        next if (&canUserDo($WebIP{$ActWebSess}->{user},'action',$act));
        my $subst = '<a href="#" onclick="javascript:alert(\'access denied\');" />';
        $$text =~ s/\<a\s+href\s*=\s*"\s*$act[^"]*?"[^>]*?\>/$subst/g;
    }
    return;
}
