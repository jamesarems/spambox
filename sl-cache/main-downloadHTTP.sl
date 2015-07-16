#line 1 "sub main::downloadHTTP"
package main; sub downloadHTTP {
    my ($gripListUrl,$gripFile,$nextload,$list,$dl,$tl,$ds,$ts) = @_;
    my $dummy = 0;
    my $showNext = 1;
    if (! $nextload || ! defined($$nextload)) {
        $nextload = \$dummy;
        $showNext = 0;
    }
    my $rc;
    my $time = time;

    my $longRetry  = $time + ( ( int( rand($dl) ) + $tl ) * 3600 ) + int(rand(3600));    # no sooner than tl hours and no later than tl+dl hours
    my $shortRetry = $time + ( ( int( rand($ds) ) + $ts ) * 3600 ) + int(rand(3600));    # no sooner than ts hours and no later than ts+ds hours

    # let's check if we really need to
    my $mtime = ftime($gripFile);
    if (-e $gripFile && $time - $mtime <= $tl * 3600 && $$nextload != 0 ) {
        # file exists and has been downloaded recently, must have been restarted
        $$nextload = $mtime + $longRetry - $time;
        $time = $$nextload - $time;
        mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
        return 0;
    }

    if ( !$CanUseLWP ) {
        mlog( 0, "ConfigError: $list download failed: LWP::Simple Perl module not available" );
        $$nextload = $longRetry;
        $time = $$nextload - $time;
        mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
        return 0;
    }

    if ( -e $gripFile ) {
    	if ( !-r $gripFile ) {
    	    mlog( 0, "AdminInfo: $list download failed: $gripFile not readable!" );
    	    $$nextload = $longRetry;
                $time = $$nextload - $time;
                mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
    	    return 0;
    	} elsif ( !-w $gripFile ) {
    	    mlog( 0, "AdminInfo: $list download failed: $gripFile not writable!" );
    	    $$nextload = $longRetry;
                $time = $$nextload - $time;
                mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
    	    return 0;
    	}
    } else {
    	if (open(my $TEMPFILE, ">", $gripFile)) {
    	    #we can create the file, this is good, now close the file and keep going.
    	    close $TEMPFILE;
    	    unlink($gripFile);
    	} else {
    	    mlog( 0, "AdminInfo: $list download failed: Cannot create $gripFile " );
    	    $$nextload = $longRetry;
                $time = $$nextload - $time;
                mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
    	    return 0;
    	}
    }

    # Create LWP object
    my $ua = LWP::UserAgent->new();

    # Set useragent to SPAMBOX version
    $ua->agent("SPAMBOX/$version$modversion ($^O; Perl/$]; LWP::Simple/$LWP::VERSION)");
    $ua->timeout(20);

    if ($proxyserver) {
        my $user = $proxyuser ? "http://$proxyuser:$proxypass\@": "http://";
        $ua->proxy( 'http', $user . $proxyserver );
        mlog( 0, "downloading $list via HTTP proxy: $proxyserver" )
          if $MaintenanceLog;
        my $la = getLocalAddress('HTTP',$proxyserver);
        $ua->local_address($la) if $la;
    } else {
        mlog( 0, "downloading $list via direct HTTP connection" ) if $MaintenanceLog;
        my ($host) = $gripListUrl =~ /^\w+:\/\/([^\/]+)/o;
        my $la = getLocalAddress('HTTP',$host);
        $ua->local_address($la) if $la;
    }

    # call LWP mirror command
    eval{$rc = $ua->mirror( $gripListUrl, $gripFile );};
    if ($@) {
        mlog( 0,"AdminInfo: $list download failed: error - " . $@ );
        $$nextload = $shortRetry;
        $time = $$nextload - $time;
        mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
        return 0;
    }

    d("LWP-response: $rc->as_string");

    if ( $rc == 304 || $rc->as_string =~ /304/o ) {
        # HTTP 304 not modified status returned
        mlog( 0, "$list already up to date" ) if $MaintenanceLog;
        $$nextload = $longRetry;
        $time = $$nextload - $time;
        mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
        return 0;
    } elsif ( ! $rc->is_success ) {
        #download failed-error code output to logfile
        my $code = $rc->as_string;
        ($code) = $code =~ /^([^\r\n]+)?\r?\n/o;
        mlog( 0,"AdminInfo: $list download failed: " . $code );
        $$nextload = $shortRetry;
        $time = $$nextload - $time;
        mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
        return 0;
    } elsif ( $rc->is_success ) {
        # download complete
        $$nextload = $longRetry;
        mlog( 0, "$list download completed" ) if $MaintenanceLog;
        $time = $$nextload - $time;
        mlog(0,"info: next $list download in ".&getTimeDiff($time)) if $MaintenanceLog && $showNext;
        return 1;
    }
}
