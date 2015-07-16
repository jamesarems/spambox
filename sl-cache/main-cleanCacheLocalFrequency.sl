#line 1 "sub main::cleanCacheLocalFrequency"
package main; sub cleanCacheLocalFrequency {
    d('cleanCacheLocalFrequency');
    unless ($LocalFrequencyInt) {%localFrequencyCache = (); return;}
    unless ($LocalFrequencyNumRcpt) {%localFrequencyCache = (); return;}
    my $adr_before= my $adr_deleted=0;
    my $t=time;
    while (my ($k,$v)=each(%localFrequencyCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $adr_before % 100;
        $adr_before++;
        my %F = split(/ /o,$v);
        foreach (sort keys %F) {
            delete $F{$_} if ($_ + $LocalFrequencyInt  < $t);
        }
        if (! scalar keys %F) {
            delete $localFrequencyCache{$k};
            $adr_deleted++;
        } else {
            $localFrequencyCache{$k} = join(' ',%F);
        }
    }
    mlog(0,"localFrequency: cleaning cache finished: addresses\'s before=$adr_before, deleted=$adr_deleted") if  $MaintenanceLog && $adr_before > 0;

    while (my ($k,$v)=each(%localFrequencyNotify)) {
        delete $localFrequencyNotify{$k} if $v < time;
    }
}
