#line 1 "sub main::ListReportGetAddr"
package main; sub ListReportGetAddr {
    my $fh = shift;
    my $this = $Con{$fh};
    d('ListReportGetAddr');
    my @addresses;
    my $mail = $this->{header};
    $mail =~ s/=([\da-fA-F]{2})/pack('C', hex($1))/geo;  # simple decode MIME quoted printable
    $mail =~ s/=\r?\n//go;

    my ($header,$body) = split(/\x0D\x0A\x0D\x0A/o,&decHTMLent(\$mail),2);
    $header = "\n".$header if $header !~ /^\n/o;
    $header .= "\r\n\r\n";
    my $rcptTag = ($this->{reportaddr} =~ /^EmailPersBlack/o) ? '' : '|to|cc|bcc';
    while ($header =~ /($HeaderNameRe):($HeaderValueRe)/gios) {
        my $val = decodeMimeWords($2);
        my $tag = $1;
        next if $tag !~ /^(?:subject|from|X-Assp-Envelope-From|sender|reply-to|errors-to|list-\w+|ReturnReceipt|Return-Receipt-To|Disposition-Notification-To$rcptTag)$/i;
        &headerSmartUnwrap($val);
        while ($val =~ /($EmailAdrRe\@$EmailDomainRe)/igo) {
            my $addr = $1;
            $addr =~ s/\r|\n//go;
            next if $addr =~ /\@.*?\.\./o;
			my ($u) = $addr =~ /^([^\@]+\@)/o;
			$u = lc $u;
            next if    ! $u
                    || $u eq lc "$EmailSpam\@"
                    || $u eq lc "$EmailHam\@"
                    || $u eq lc "$EmailWhitelistAdd\@"
                    || $u eq lc "$EmailWhitelistRemove\@"
                    || $u eq lc "$EmailRedlistAdd\@"
                    || $u eq lc "$EmailHelp\@"
                    || $u eq lc "$EmailAnalyze\@"
                    || $u eq lc "$EmailRedlistRemove\@"
                    || $u eq lc "$EmailSpamLoverAdd\@"
                    || $u eq lc "$EmailSpamLoverRemove\@"
                    || $u eq lc "$EmailNoProcessingAdd\@"
                    || $u eq lc "$EmailNoProcessingRemove\@"
                    || $u eq lc "$EmailBlackAdd\@"
                    || $u eq lc "$EmailBlackRemove\@"
                    || $u eq lc "$EmailBlockReport\@"
                    || $u eq lc "$EmailPersBlackAdd\@"
                    || $u eq lc "$EmailPersBlackRemove\@"
                    || $u =~ /^RSBM_.+?\Q$maillogExt\E\@$/i;
            next if ($addr =~ /^\Q$this->{mailfrom}\E$/i);
            mlog($fh,"report-header: found address $addr in header tag") if $ReportLog >= 2;
            push @addresses,&batv_remove_tag(0,$addr,'');
        }
    }
    mlog($fh,"report-header: found addresses in MIME-header - addresses in mail body are ignored!") if $ReportLog > 1 && @addresses;
    mlog($fh,"report-header: no addresses found in MIME header tags") if $ReportLog >= 2 && ! @addresses;
    return @addresses if @addresses;

    while ($body =~ /((?:$EmailAdrRe|\*)\@(?:\*|\*\.)?$EmailDomainRe)\s*(,(?:\*|\@$EmailDomainRe)|=>\s*\d+(?:\.\d+)?)?/go) {
        my $addr = $1.$2;
        next if $addr =~ /\@.*?\.\./o;
        next if ($addr =~ /^\Q$this->{mailfrom}\E(?:,\*)?$/i);
        next if ($addr =~ /=>/o && $this->{reportaddr} !~ /^EmailSpamLover/o);
        $addr =~ s/=>.*$//o if $this->{reportaddr} ne 'EmailSpamLoverAdd';
        next if ($addr =~ /\*/o && $this->{reportaddr} !~ /^EmailPersBlack/o);
        my ($u) = $addr =~ /^([^\@]+\@)/o;
		$u = lc $u;
        next if    ! $u
                || $u eq lc "$EmailSpam\@"
                || $u eq lc "$EmailHam\@"
                || $u eq lc "$EmailWhitelistAdd\@"
                || $u eq lc "$EmailWhitelistRemove\@"
                || $u eq lc "$EmailRedlistAdd\@"
                || $u eq lc "$EmailHelp\@"
                || $u eq lc "$EmailAnalyze\@"
                || $u eq lc "$EmailRedlistRemove\@"
                || $u eq lc "$EmailSpamLoverAdd\@"
                || $u eq lc "$EmailSpamLoverRemove\@"
                || $u eq lc "$EmailNoProcessingAdd\@"
                || $u eq lc "$EmailNoProcessingRemove\@"
                || $u eq lc "$EmailBlackAdd\@"
                || $u eq lc "$EmailBlackRemove\@"
                || $u eq lc "$EmailBlockReport\@"
                || $u eq lc "$EmailPersBlackAdd\@"
                || $u eq lc "$EmailPersBlackRemove\@"
                || $u =~ /^RSBM_.+?\Q$maillogExt\E\@$/i;
        mlog($fh,"report-body: found address $addr in mail body") if $ReportLog >= 2;
        $addr =~ s/\r|\n//go;
        push @addresses,&batv_remove_tag(0,$addr,'');
    }
    mlog($fh,"report-body: no addresses found in mail body") if $ReportLog >= 2 && ! @addresses;
    return @addresses;
}
