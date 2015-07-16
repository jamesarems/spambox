#line 1 "sub main::ListReportExec"
package main; sub ListReportExec {
    my ( $ad, $this ) = @_;
    
    d("ListReportExec - $ad");

    my $ea = ${$this->{reportaddr}} .'@';

    return unless $ad =~ s/((?:$EmailAdrRe|\*)\@)((?:\*|\*\.)?$EmailDomainRe)\s*(,(?:\*|\@$EmailDomainRe)|=>\s*\d+(?:\.\d+)?)?/$1$2/o;     #addr@dom,[*][@domain] for global removal of whitelist
    my $global; my $globalstr; my $splw;
    my $localmail = localmail($2);
    $globalstr = $3;
    if (substr($globalstr,0,2) =~ /,[\*\@]/o) {$global = 1;};
    return if substr($globalstr,0,2) eq '=>' && $this->{reportaddr} ne 'EmailSpamLoverAdd';
    $splw = $globalstr if substr($globalstr,0,2) eq '=>' && $this->{reportaddr} eq 'EmailSpamLoverAdd';
    $splw =~ s/\s//go;
    $globalstr = '' unless $global;
    $localmail = undef if ($this->{reportaddr} =~ /^EmailPersBlack/o && $ad =~ /^reportpersblack\@/io);
    return if ($ad =~ /\*/o && $this->{reportaddr} !~ /^EmailPersBlack/o);
    return if matchSL( $ad, 'EmailAdmins' );
    return if $ad =~ /\=/o && !$EmailAllowEqual;
    return if $localmail && $ReportTypes{$this->{reportaddr}} <= 3;

    $ad =~ s/^\'//o;
    $ad =~ s/^title.3D//o;
    my $mf  = $ad;
    my $rea = $ad;
    $rea =~ s/^\*/\\\*/o;
    my $mfu; $mfu = $1 if $mf =~ /([^@]*)\@/o;
    my $mfd; $mfd = $1 if $mf =~ /\@([^@]*)/o;
    my $mfdd; $mfdd = $1 if $mf =~ /(\@[^@]*)/o;
    my $alldd        = "$wildcardUser$mfdd";
    my $defaultalldd = "*$mfdd";
    return if !( $mfu || $mfd || $mfdd ) && $ReportTypes{$this->{reportaddr}} <= 9;
    return if lc $mfu  eq lc $ea && $localmail;
    return if lc $mfd  eq lc $ea && $localmail;
    return if lc $mfdd eq lc $ea && $localmail;
    return if $this->{reportaddr} eq 'EmailWhitelistAdd' && $localmail;
    return if $this->{reportaddr} eq 'EmailWhitelistRemove' && $localmail;

    return if length($ad) > 127;

    return if $ad =~ /^\Q$EmailAdminReportsTo/i && $EmailAdminReportsTo;
    return if $ad =~ /^\Q$EmailHam/i;
    return if $ad =~ /^\Q$EmailSpam/i;
    return if $ad =~ /^\Q$EmailErrorsTo/i       && $EmailErrorsTo;
    return if $ad =~ /^\Q$EmailRedlistAdd/i;
    return if $ad =~ /^\Q$EmailRedlistRemove/i;
    return if $ad =~ /^\Q$EmailRedlistTo/i      && $EmailRedlistTo;
    return if $ad =~ /^\Q$EmailWhitelistAdd/i;
    return if $ad =~ /^\Q$EmailWhitelistRemove/i;
    return if $ad =~ /^\Q$EmailWhitelistTo/i    && $EmailWhitelistTo;
    return if $ad =~ /^\Q$EmailSpamLoverAdd/i;
    return if $ad =~ /^\Q$EmailSpamLoverRemove/i;
    return if $ad =~ /^\Q$EmailSpamLoverTo/i    && $EmailSpamLoverTo;
    return if $ad =~ /^\Q$EmailNoProcessingAdd/i;
    return if $ad =~ /^\Q$EmailNoProcessingRemove/i;
    return if $ad =~ /^\Q$EmailNoProcessingTo/i && $EmailNoProcessingTo;
    return if $ad =~ /^\Q$EmailBlackAdd/i;
    return if $ad =~ /^\Q$EmailBlackRemove/i;
    return if $ad =~ /^\Q$EmailBlackTo/i        && $EmailBlackTo;
    return if $ad =~ /^\Q$EmailPersBlackAdd/i;
    return if $ad =~ /^\Q$EmailPersBlackRemove/i;

    return if $ad =~ /\.(jpg|gif)\@/o;
    return if $ad =~ /\*\*/o;
    return if $ad =~ /mailfrom/io;
    return if lc $ad eq lc $this->{mailfrom} && $ReportTypes{$this->{reportaddr}} <= 3;

    return if $this->{reportaddr} eq 'EmailHelp';
    return if $ad =~ /\Q$EmailFrom/i;
    my $isadmin = (
        matchSL( $this->{mailfrom}, 'EmailAdmins' )
          or lc $this->{mailfrom} eq lc $EmailAdminReportsTo
    );
    $global = 0 unless $isadmin;
    
    if ( $EmailErrorsModifyWhite == 2 && ($this->{reportaddr} eq 'EmailSpam' or $this->{reportaddr} eq 'EmailHam') ) {
        ShowWhiteReport( $ad, $this );
        return;
    }
    my $t       = time;
    my $redlist = "Redlist";
    my $list = ( ( $ReportTypes{$this->{reportaddr}} & 4 ) == 0 ) ? "Whitelist" : "Redlist";

    if (   $this->{reportaddr} eq 'EmailWhitelistRemove'
        || $this->{reportaddr} eq 'EmailSpam'
        || $this->{reportaddr} eq 'EmailRedlistRemove' )
    {

        # deletion
        if ( !$isadmin && lc $this->{mailfrom} ne lc $EmailRedlistTo ) {
            $ad = $this->{mailfrom} if $list eq $redlist;
        }

        if ( ($list eq 'Redlist' && $list->{ lc $ad }) || ($list eq 'Whitelist') && &Whitelist($ad,$this->{mailfrom},'')) {

            ($list eq 'Redlist') ? delete $list->{ lc $ad } : &Whitelist($ad,$this->{mailfrom},'delete');
            my @wout;
            if ($list eq 'Whitelist') {
                @wout = @WhitelistResult;
                $globalstr =~ s/^,//o;
                if ($globalstr) {
                    &Whitelist($ad,$globalstr,'delete');
                    push @wout, @WhitelistResult;
                }
                @wout = map {my $t=$_;$t=~s/<br \/>/\n/o;$t} @wout;
                map {
                        if ($this->{report} !~ /\Q$_\E/) {
                            $this->{report} .= "$_\n";
                            mlog( 0, "email: $_" );
                        }
                    } @wout;
            }

            if ( ($list eq 'Redlist') && $this->{report} !~ /\Q$rea\E: removed from/ )
            {
                $this->{report} .= "$ad: removed from " . lc $list . "\n";
                mlog( 0, "email: " . lc $list . " deletion: $ad" );
            }

            # we're adding to redlist
            if (( $this->{reportaddr} eq 'EmailWhitelistAdd'
                  || $this->{reportaddr} eq 'EmailHam'
                  || $this->{reportaddr} eq 'EmailRedlistAdd'
                )
                && $EmailWhiteRemovalToRed
              )
            {
                if ( $redlist->{ lc $ad } ) {
                    $redlist->{ lc $ad } = $t;
                    if (   $this->{report} !~ /\Q$ad\E: added to/
                        && $this->{report} !~ /\Q$ad\E: already on/)
                    {
                        $this->{report} .= "$ad: already on " . lc $redlist . "\n";
                    }
                }
                else {
                    $redlist->{ lc $ad } = $t;
                    if (   $this->{report} !~ /\Q$ad\E: added to/
                        && $this->{report} !~ /\Q$ad\E: already on/
                      )
                    {
                        $this->{report} .= "$ad: added to " . lc $redlist . "\n";
                        mlog( 0, "email: " . lc $redlist . " addition: $ad" );
                    }
                }
            }
        }
        else {
            if ( ( $this->{reportaddr} eq 'EmailSpam' ) ) {
            }
            else {
                if ( $this->{report} !~ /\Q$rea\E: not on/ )
                {
                    $this->{report} .= "$ad: not on " . lc $list . " - not removed\n";
                }
            }
        }

        if ($EmailErrorsModifyNoP) {

            if ( matchSL( $mf, 'noProcessing' ) ) {
                if ( $this->{report} !~ /\Q$mf\E is on NoProcessing-List/ )
                {
                    if ($EmailErrorsModifyNoP == 2) {
                        $this->{report} .= "\n$mf is on NoProcessing-List\n\n";
                        PrintAdminInfo("email $mf is on NoProcessing-List");
                    }
                    if (   $EmailErrorsModifyNoP == 1
                        && modifyList('noProcessing' , 'delete' ,"email from $this->{mailfrom}", $mf )
                       )
                    {
                        $this->{report} .= "\n$mf deleted from NoProcessing-List\n\n";
                        PrintAdminInfo("email $mf deleted from NoProcessing-List");
                    }
                }
            }
            if ( matchSL( $mfdd, 'noProcessing' ) ) {
                if ( $this->{report} !~ /\Q$mfdd\E is on NoProcessing-List/ )
                {
                    if ($EmailErrorsModifyNoP == 2) {
                        $this->{report} .= "\n$mfdd is on NoProcessing-List\n\n";
                        PrintAdminInfo("email $mfdd is on NoProcessing-List");
                    }
                    if (   $EmailErrorsModifyNoP == 1
                        && modifyList( 'noProcessing' ,'delete' ,"email from $this->{mailfrom}", $mfdd )
                       )
                    {
                        $this->{report} .="\n$mfdd deleted from NoProcessing-List\n\n";
                        PrintAdminInfo("email $mfdd deleted from NoProcessing-List");
                    }
                }
            }

            if ($npRe) {
                if ( $mf =~ /$npReRE/ ) {
                    if ( $this->{report} !~ /\Q$mf\E is on NoProcessing-Regex/ )
                    {
                        $this->{report} .=
                          "\n$mf is in NoProcessing-Regex\n\n";
                    }
                }
            }
            if ( $noProcessingDomains && $mf =~ /($NPDRE)/ ) {
                my $r = $1;
                if ( $this->{report} !~ /\Q$r\E is on NoProcessingDomain-List/ )
                {
                    $this->{report} .=
                      "\n$1 is on NoProcessingDomain-List\n\n";
                }
            }
        }
        if ( &Whitelist($alldd) ) {
            $this->{report} .= "\n$alldd is on Whitelist\n\n";
        }
        if ( &Whitelist($defaultalldd) ) {
            $this->{report} .= "\n$defaultalldd is on Whitelist\n\n";
        }
        if ( &Whitelist($mf) ) {
            if ( $this->{report} !~ /\Q$rea\E is on Whitelist/ )
            {
                $this->{report} .= "\n$mf is on Whitelist\n\n";
            }
        }
        if ( &Whitelist($mf,$this->{mailfrom}) ) {
            if ( $this->{report} !~ /\Q$mf,$this->{mailfrom}\E is on Whitelist/ )
            {
                $this->{report} .= "\n$mf,$this->{mailfrom} is on Whitelist\n\n";
            }
        }
        if ( $whiteListedDomains && matchRE([$mf,"$mf,$this->{mailfrom}"],'whiteListedDomains',1) ) {
            if ( $this->{report} !~ /\Q$lastREmatch\E is on Whitedomain-List/ )
            {
                $this->{report} .= "\n$lastREmatch is on Whitedomain-List\n\n";
            }
        }
    }
    elsif (   $this->{reportaddr} eq 'EmailHam'
           || $this->{reportaddr} eq 'EmailWhitelistAdd'
           || $this->{reportaddr} eq 'EmailRedlistAdd' )
    {
        if ( ! matchSL( $this->{mailfrom}, 'EmailAdmins' ) ) {
            $ad = $this->{mailfrom}
              if $list eq $redlist
                  && lc $this->{mailfrom} ne lc $EmailAdminReportsTo
                  && lc $this->{mailfrom} ne lc $EmailRedlistTo;
        }

        # addition
        my $removePersBlack;
        my $aa = $ad;
        $aa =~ s/([\.\[\]\-\(\)\+\\])/\\$1/go;
        $aa =~ s/^\*/\\\*/o;

        if ( ($list eq 'Redlist' && $list->{ lc $ad }) || ($list eq 'Whitelist') && &Whitelist($ad,$this->{mailfrom},'')) {
            ($list eq 'Redlist') ? $list->{ lc $ad } = $t : &Whitelist($ad,$this->{mailfrom},'add');
            $removePersBlack = 1 if $list eq 'Whitelist';
            if (   $this->{report} !~ /\Q$aa\E: already on/
                && $this->{report} !~ /\Q$aa\E: added to/ )
            {
                $this->{report} .= "$ad: already on " . lc $list . "\n";
                mlog( 0, "email: $ad already on " . lc $list, 1 );
            }
            # mlog($fh,"email ".lc $list." renewal: $ad");
        }
        elsif ( $localmail
            && ( $this->{reportaddr} eq 'EmailWhitelistAdd' || $this->{reportaddr} eq 'EmailHam' ) )
        {
        }
        elsif ( $list eq 'Whitelist' && $Redlist{ lc $ad } ) {
            if ( $this->{report} !~ /\Q$aa:\E cannot add redlisted users to whitelist/ )
            {
                $this->{report} .= "$ad: cannot add redlisted users to whitelist\n";
                mlog( 0, "email whitelist addition denied: $ad on redlist", 1 );
            }
        }
        else {
            ($list eq 'Redlist') ? $list->{ lc $ad } = $t : &Whitelist($ad,$this->{mailfrom},'add');
            $removePersBlack = 1 if $list eq 'Whitelist';
            if (   $this->{report} !~ /\Q$aa\E: already on/
                && $this->{report} !~ /\Q$aa\E: added to/ )
            {
                $this->{report} .= "$ad: added to " . lc $list . "\n";
                mlog( 0, "email: " . lc $list . " addition: $ad", 1 );
            }
            if (   $this->{report} !~ /\Q$aa,$this->{mailfrom}\E: already on/
                && $this->{report} !~ /\Q$aa,$this->{mailfrom}\E: added to/
                && ! $isadmin )
            {
                if ($this->{mailfrom} && $list eq 'Whitelist') {
                    $this->{report} .= "$ad,$this->{mailfrom}: added to " . lc $list . "\n";
                    mlog( 0, "email: " . lc $list . " addition: $ad,$this->{mailfrom}", 1 );
                }
            }
        }
        if ($removePersBlack && (my $pb = PersBlackFind($this->{mailfrom},$ad))) {
            PersBlackRemove($this->{mailfrom},$ad);
            $this->{report} .= "$pb: deleted from the personal blacklist of $this->{mailfrom} , address $ad is now whitelisted\n";
            mlog( 0, "email: $pb: deleted from the personal blacklist of $this->{mailfrom}", 1 );
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailPersBlackAdd' && ! $localmail && $ad !~ /^$skipAddrListRE$/o) {  # personal black add
        if ($ad =~ /^reportpersblack\@/io) {
            my $fr = lc $this->{mailfrom} . ',';
            $this->{report} .= "\n";
            while (my ($k,$v) = each %PersBlack) {
                $PersBlackHasRecords = 1;
                if ($k =~ /^\Q$fr\E/) {
                    my ($ar,$af) = split(/,/o,$k);
                    $this->{report} .= "$af: is on the personal blacklist of $ar\n";
                }
            }
        } else {
            my $action = ( PersBlackFind($this->{mailfrom},$ad) ) ? 'updated' : 'added';
            $PersBlack{lc $this->{mailfrom}.','.lc $ad} = $t if $action eq 'added';
            $PersBlackHasRecords = 1;
            $this->{report} .= "$ad: $action to the personal blacklist of $this->{mailfrom}\n";
            mlog( 0, "email: personal blacklist $action: $this->{mailfrom},$ad", 1 );
            if (&Whitelist($ad,$this->{mailfrom})) {
                &Whitelist($ad,$this->{mailfrom},'delete');
                $this->{report} .= "$ad,$this->{mailfrom}: deleted from Whitelist - address is now personal black\n";
                mlog( 0, "email: Whitelist deletion: $ad,$this->{mailfrom}" );
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailPersBlackRemove' && ! $localmail) {  # personal black remove
        if (my $pb = PersBlackFind($this->{mailfrom},$ad)) {
            PersBlackRemove($this->{mailfrom},$ad);
            $this->{report} .= "$pb: deleted from the personal blacklist of $this->{mailfrom}\n";
            mlog( 0, "email: $pb: deleted from the personal blacklist of $this->{mailfrom}", 1 );
        } else {
            if ($ad =~ /^reportpersblack\@/io) {
                my $fr = lc $this->{mailfrom} . ',';
                $this->{report} .= "\n";
                while (my ($k,$v) = each %PersBlack) {
                    $PersBlackHasRecords = 1;
                    if ($k =~ /^\Q$fr\E/) {
                        my ($ar,$af) = split(/,/o,$k);
                        $this->{report} .= "$af: is on the personal blacklist of $ar\n";
                    }
                }
            } else {
                $this->{report} .= "$ad: not on the personal blacklist of $this->{mailfrom}\n";
            }
        }
        if ($isadmin && $global) {
            my $fr = ','.lc $ad;

            if ("$PersBlackObject" =~ /Tie\:\:RDBM/o) {
                delete $PersBlack{"\*$fr"};
                $this->{report} .= "ad: completely deleted from the personal blacklist\n";
                mlog( 0, "email: ad: completely deleted from the personal blacklist", 1 );
            } else {
                my $i;
                while (my ($k,$v) = each %PersBlack) {
                    if ($k =~ /\Q$fr\E$/i) {
                        my ($ar,$af) = split(/,/o,$k);
                        delete $PersBlack{$k};
                        $this->{report} .= "$af: deleted from the personal blacklist of $ar\n";
                        mlog( 0, "email: $af: deleted from the personal blacklist of $ar", 1 );
                    }
                    unless (++$i % 1000) {
                        $WorkerLastAct{$WorkerNumber} = time if $WorkerNumber > 0 && $WorkerNumber < 10000;
                    }
                }
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailSpamLoverAdd' ) {

        # SpamLover add
        if ( !matchSL( $this->{mailfrom}, 'EmailAdmins' ) ) {
            $ad = $this->{mailfrom}
              if lc $this->{mailfrom} ne lc $EmailAdminReportsTo
                  && lc $this->{mailfrom} ne lc $EmailSpamLoverTo;
        }
        if ( &matchSL( $ad, 'spamLovers' ) ) {    # is already SL
            if (   $this->{report} !~ /\Q$ad\E: already on/
                && $this->{report} !~ /\Q$ad\E: added to/ )
            {
                $this->{report} .=
                  "$ad: already on SpamLover addresses - not added\n";
            }
        }
        else {
            # add to SL
            if (   $this->{report} !~ /\Q$ad\E: already on/
                && $this->{report} !~ /\Q$ad\E: added to/ )
            {
                if ($spamLovers =~ /^ *file: *(.+)/io ) {
                    modifyList('spamLovers' ,'add', "email interface from $this->{mailfrom}" , $ad . $splw);
                }
                else {
                    $this->{report} .= "error: spamLovers is missconfigured (missing file:...) - unable to add $ad\n";
                    return;
                }
                $this->{report} .= "$ad: added to SpamLover addresses\n";
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailBlackAdd' ) {

        # Black add
        if ( !$isadmin ) {
            $this->{report} .= "$this->{mailfrom}: blacklist addition not allowed\n";
            return;
        }
        if ( $blackListedDomains && matchRE([$ad],'blackListedDomains',1) ) {    # is already black
            if (   $this->{report} !~ /\Q$ad\E: already on/
                && $this->{report} !~ /\Q$ad\E: added to/ )
            {
                $this->{report} .= "$ad: already in blackDomains addresses - not added\n";
            }
        }
        else {

            # Black addL
            if (   $this->{report} !~ /\Q$ad\E: already on/
                && $this->{report} !~ /\Q$ad\E: added to/
                && ! localdomains($ad))
            {
                if ( $blackListedDomains =~ /^ *file: *(.+)/io ) {
                    modifyList('blackListedDomains' ,'add', "email interface from $this->{mailfrom}", $ad);
                }
                else {
                    $this->{report} .= "error: blackListedDomains is missconfigured (missing file:...) - unable to add $ad\n";
                    return;
                }
                $this->{report} .= "$ad: added to blackListedDomains addresses\n";
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailNoProcessingAdd' ) {

        # NoProcessing add
        if ( !matchSL( $this->{mailfrom}, 'EmailAdmins' ) ) {
            $ad = $this->{mailfrom}
              if lc $this->{mailfrom} ne lc $EmailAdminReportsTo
                  && lc $this->{mailfrom} ne lc $EmailNoProcessingTo;
        }

        if ( &matchSL( $ad, 'noProcessing' ) ) {    # is already NP
            if (   $this->{report} !~ /\Q$ad\E: already on/
                && $this->{report} !~ /\Q$ad\E: added to/ )
            {
                $this->{report} .= "$ad: already on noProcessing addresses - not added\n";
            }
        }
        else {
            if (   $this->{report} !~ /\Q$ad\E: already on/
                && $this->{report} !~ /\Q$ad\E: added to/ )
            {
                if ( $noProcessing =~ /^ *file: *(.+)/io ) {
                    modifyList('noProcessing' ,'add',"email interface from $this->{mailfrom}", $ad);
                }
                else {
                    $this->{report} .= "error: noProcessing is misconfigured (missing file:...) - unable to add $ad\n";
                    return;
                }
                $this->{report} .= "$ad: added to noProcessing addresses\n";
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailNoProcessingRemove' ) {

        # NP remove
        if ( !matchSL( $this->{mailfrom}, 'EmailAdmins' ) ) {
            $ad = $this->{mailfrom}
              if lc $this->{mailfrom} ne lc $EmailAdminReportsTo
                  && lc $this->{mailfrom} ne lc $EmailNoProcessingTo;
        }

        if ( !&matchSL( $ad, 'noProcessing' ) ) {    # is not a NP
            if ( $this->{report} !~ /\Q$ad\E: is not a/ )
            {
                $this->{report} .= "$ad: is not a noProcessing address - not removed\n";
            }
        }
        else {
            if (   $this->{report} !~ /\Q$ad\E: removed from/
                && $this->{report} !~ /\Q$ad\E: unable to remove/ )
            {
                my $removed = 0;
                if ( $noProcessing =~ /^ *file: *(.+)/io ) {
                    $removed = modifyList('noProcessing' ,'delete', "email interface from $this->{mailfrom}", $ad);
                }
                else {
                    $this->{report} .= "error: noProcessing is misconfigured (missing file:...) - unable to remove $ad\n";
                    return;
                }
                if ($removed) {
                    $this->{report} .= "$ad: removed from noProcessing addresses\n";
                } else {
                    $this->{report} .= "$ad: unable to remove from noProcessing addresses\n";
                }
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailBlackRemove' ) {

        # Black remove
        if ( !$isadmin ) {
            $this->{report} .= "$this->{mailfrom}: blacklist removal not allowed\n";
            return;
        }
        if ( $blackListedDomains && ! matchRE([$ad],'blackListedDomains',1) )
        {    # is not a blackListedDomains
            if ( $this->{report} !~ /\Q$ad\E: is not a/ )
            {
                $this->{report} .= "$ad: is not a blackListedDomains address - not removed\n";
            }
        }
        else {
            if (   $this->{report} !~ /\Q$ad\E: removed from/
                && $this->{report} !~ /\Q$ad\E: unable to remove/ )
            {

                my $removed = 0;
                if ( $blackListedDomains =~ /^ *file: *(.+)/io ) {
                    $removed = modifyList('blackListedDomains' ,'delete', "email interface from $this->{mailfrom}", $ad);
                }
                else {
                    $this->{report} .= "error: blackListedDomains is misconfigured (missing file:...) - unable to remove $ad\n";
                    return;
                }
                if ($removed) {
                    $this->{report} .= "$ad: removed from blackListedDomains addresses\n";
                } else {
                    $this->{report} .= "$ad: unable to remove from blackListedDomains addresses\n";
                }
            }
        }
    }
    elsif ( $this->{reportaddr} eq 'EmailSpamLoverRemove' ) {
        # SpamLover remove
        if ( !matchSL( $this->{mailfrom}, 'EmailAdmins' ) ) {
            $ad = $this->{mailfrom}
              if lc $this->{mailfrom} ne lc $EmailAdminReportsTo
                  && lc $this->{mailfrom} ne lc $EmailSpamLoverTo;
        }
        if ( !&matchSL( $ad, 'spamLovers' ) ) {
            if ( $this->{report} !~ /\Q$ad\E: is not a/ )
            {
                $this->{report} .= "$ad: is not a SpamLover address - not removed\n";
                      # is not a SL
            }
        }
        else {
            if (   $this->{report} !~ /\Q$ad\E: removed from/
                && $this->{report} !~ /\Q$ad\E: unable to remove/ )
            {          # remove from SL
                my $removed = 0;
                if ( $spamLovers =~ /^ *file: *(.+)/io ) {
                    $removed = modifyList('spamLovers' ,'delete', "email interface from $this->{mailfrom}", $ad);
                }
                else {
                    $this->{report} .= "error: spamLovers is misconfigured (missing file:...) - unable to remove $ad\n";
                    return;
                }
                if ($removed) {
                    $this->{report} .= "$ad: removed from SpamLover addresses\n";
                    mlog(0,"email: SpamLover removed: $ad by $this->{mailfrom}",1);
                }
                else {
                    $this->{report} .= "$ad: unable to remove from SpamLover addresses\n";
                }
            }
        }
    }
}
