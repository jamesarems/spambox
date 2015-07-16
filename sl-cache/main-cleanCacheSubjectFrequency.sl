#line 1 "sub main::cleanCacheSubjectFrequency"
package main; sub cleanCacheSubjectFrequency {
    d('cleanCacheSubjectFrequency');
    unless ($subjectFrequencyInt) {%subjectFrequencyCache = (); return;}
    my $adr_before = my $adr_deleted=0;
    my $t=time;
    while (my ($k,$v)=each(%subjectFrequencyCache)) {
        &ThreadMaintMain2() if $WorkerNumber == 10000 && ! $adr_before % 100;
        $adr_before++;
        my %F = split(/ /o,$v);
        foreach (sort keys %F) {
            delete $F{$_} if ($_ + $subjectFrequencyInt  < $t);
        }
        if (! scalar keys %F) {
            delete $subjectFrequencyCache{$k};
            $adr_deleted++;
        } else {
            $subjectFrequencyCache{$k} = join(' ',%F);
        }
    }
    mlog(0,"subjectFrequency: cleaning cache finished: subjects before=$adr_before, deleted=$adr_deleted") if  $MaintenanceLog && $adr_before > 0;
}
