#line 1 "sub main::fixV1ConfigSettings"
package main; sub fixV1ConfigSettings {
# if we are upgrading from a version with mysql-only support - set correct the possible config values
    if (!$Config{DBdriver}) {    # this is never set if we are upgrading such a version
        $Config{DBdriver} = "mysql" if ($Config{whitelistdb}.$Config{redlistdb}.$Config{delaydb}.$Config{pbdb}.$Config{spamdb} =~ /mysql/o);
        $Config{whitelistdb} = "DB:" if ($Config{whitelistdb} =~ /mysql/o);
        $Config{redlistdb} = "DB:" if ($Config{redlistdb} =~ /mysql/o);
        $Config{delaydb} = "DB:" if ($Config{delaydb} =~ /mysql/o);
        $Config{pbdb} = "DB:" if ($Config{pbdb} =~ /mysql/o);
        $Config{spamdb} = "DB:" if ($Config{spamdb} =~ /mysql/o);
    }

# fix the SSL settings from V1
    if (exists $Config{enableSSL}) {
        $Config{DoTLS} = 2 if $Config{enableSSL};
        delete $Config{enableSSL};
    }

# fix webSecondaryPort from V1
    if (exists $Config{webSecondaryPort}) {
        if ($Config{webAdminPort} && $Config{webSecondaryPort}) {
            $Config{webAdminPort} .= '|' . $Config{webSecondaryPort};
        } elsif ( ! $Config{webAdminPort} && $Config{webSecondaryPort}) {
            $Config{webAdminPort} = $Config{webSecondaryPort};
        }
        delete $Config{webSecondaryPort};
    }
    if ($Config{EmailErrorsModifyPersBlack} == 1) {
        $Config{EmailErrorsModifyPersBlack} = '*@*';
    } else {
        $Config{EmailErrorsModifyPersBlack} = '';
    }

    $Config{Notify} =~ s/\|/,/go;

    $Config{Bayesian_localOnly} = $Config{yesBayesian_local} if (exists $Config{yesBayesian_local} && ! exists $Config{Bayesian_localOnly});

    $Config{PBTrapInterval} = $Config{PBTrapCacheInterval} if (exists $Config{PBTrapCacheInterval} && ! exists $Config{PBTrapInterval});
    $Config{SBCacheExp} = $Config{SBCacheInterval} if (exists $Config{SBCacheInterval} && ! exists $Config{SBCacheExp});
    $Config{RBLCacheExp} = $Config{RBLCacheInterval} if (exists $Config{RBLCacheInterval} && ! exists $Config{RBLCacheExp});
    $Config{RestartEvery} = $Config{AutoRestartInterval} if (exists $Config{AutoRestartInterval} && ! exists $Config{RestartEvery});

    if ($Config{HideIP} or $Config{HideHelo}) {
        $Config{HideIPandHelo} = "$Config{HideIP} $Config{HideHelo}";
    }

    # correct the RebuildSchedule
    if (! isSched($Config{RebuildSchedule}) && $Config{RebuildSchedule} && $Config{RebuildSchedule} =~ /(24)|^(\d+)/o ) {
        $Config{RebuildSchedule} = '0 ' . ($1 || $2) . ' * * *';
    } else {
        $Config{RebuildSchedule} = 'noschedule';
    }

    $Config{subjectFrequencyInt} = $Config{maxSameSubjectExpiration} if (exists $Config{maxSameSubjectExpiration});
    $Config{subjectFrequencyNumSubj} = $Config{maxSameSubject} if (exists $Config{maxSameSubject});

    if (exists $Config{NotSpamTag} && $Config{NotSpamTag} && length($Config{NotSpamTag}) < 12) {
        my $r = int(12 / length($Config{NotSpamTag})) + 1;
        $Config{NotSpamTag} = $Config{NotSpamTag} x $r;
    }
    $Config{NotSpamTagProc} = 1 if $Config{NotSpamTagAutoWhite};
    if ($Config{NotSpamTagRandom} && ! $Config{NotSpamTag}) {
        for (0...79) {
              $Config{NotSpamTag} .= chr(int(rand(94))+33);
        }
    }

    $Config{Bayesian_localOnly} = $Config{yesBayesian_local} if (exists $Config{yesBayesian_local});

    if ( eval {require V1upgrade} ) {
        V1upgrade::convert(\%Config);
        unloadNameSpace('V1upgrade');
        rename("$base/lib/V1upgrade.pm","$base/lib/V1upgrade.pm.was_run") or
        die "UPGRADE-ERROR: unable to rename '$base/lib/V1upgrade.pm' to '$base/lib/V1upgrade.pm.was_run' - $!\n";
    }
}
