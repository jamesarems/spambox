#line 1 "sub main::ConfigChangeNormUnicode"
package main; sub ConfigChangeNormUnicode {
    my ($name, $old, $new, $init)=@_;
    return if $new eq $old && ! $init;
    mlog(0,"AdminUpdate: $name updated from '$old' to '$new'")  unless $init || $new eq $old;
    if ($new) {
        return ConfigShowError(0,"warning: $name was enabled, your Perl version is $], but at least Perl version 5.012000 (5.12.0) is required for unicode normalization!") if $] lt '5.012000';
        eval('use Unicode::Normalize();1;') ||
        return ConfigShowError(0,"warning: $name was enabled, but the required Perl module Unicode::Normalize is not available");
    }
    return if $WorkerNumber != 0;
    ${$name} = $Config{$name} = $new;
    if ($new) {
        $CanUseUnicodeNormalize = 1;
        $requiredDBVersion{'Spamdb'} =~ s/^(\d_\d{5}_[\d.]+)(_UAX\#29)?(?:_UAX\#15)?(_WordStem[\d.]+)?$/$1.$2 . '_UAX#15' . $3/oe;
        $requiredDBVersion{'HMMdb'}  =~ s/^(\d_\d{5}_[\d.]+)(_UAX\#29)?(?:_UAX\#15)?(_WordStem[\d.]+)?$/$1.$2 . '_UAX#15' . $3/oe;
    } else {
        $requiredDBVersion{'Spamdb'} =~ s/_UAX\#15//o;
        $requiredDBVersion{'HMMdb'}  =~ s/_UAX\#15//o;
    }
    foreach (keys %Threads) {
        next if $_ == 0;
        $ComWorker{$_}->{recompileAllRe} = 1;
        threads->yield();
        $recompileAllRe = 1;
    }
}
