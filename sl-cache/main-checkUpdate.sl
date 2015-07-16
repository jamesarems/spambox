#line 1 "sub main::checkUpdate"
package main; sub checkUpdate {
    my ($name,$valid,$onchange,$desc)=@_;
    return '' unless %qs;
    unless (exists $Config{$name}) {
        mlog(0,"warning: config parm $name requested but $name is not defined") if $name !~ /^AD/o;
        return '';
    }
    if (exists $qs{'AD'.$name}) {
#        mlog(0,"info: QS AD$name found");  # access denied and/or hidden
        return '';
    }
    if($qs{$name} ne $Config{$name}) {
        if($qs{$name}=~/$valid/i && $qs{$name} eq $1) {
            my $new=$1; my $info;
            my $old=$Config{$name};
            $Config{$name}=$new;
            if($onchange) {
                $info=$onchange->($name,$old,$new,'',$desc);
            } else {
                my $dold = $old;
                my $dnew = $new;
                if (exists  $ConfigListBox{$name}) {
                    if (exists $ConfigListBoxAll{$name}) {
                        $dold = decHTMLent($ConfigListBoxAll{$name}{$old}." ($old)");
                        $dnew = decHTMLent($ConfigListBoxAll{$name}{$new}." ($new)");
                    } elsif ($ConfigListBox{$name} =~ /^O(?:n|ff)$/o) {
                        $dold = $old ? 'On' : 'Off';
                        $dnew = $new ? 'On' : 'Off';
                    }
                }
                my $text = exists $cryptConfigVars{$name} ? '' : "from '$dold' to '$dnew'";
                mlog(0,"AdminUpdate: $name changed $text") unless $new eq $old;
                ${$name}=$new;
    # -- this sets the variable name with the same name as the config key to the new value
    # -- for example $Config{myName}="SPAMBOX-nospam" -> $myName="SPAMBOX-nospam";
            }
            $ConfigChanged = 1 unless exists $RunTaskNow{$name};
            if ($info !~ /span class.+?negative/o) {
                if ($new ne $old) {
                    my $ret = "<span class=\"positive\"><b>*** Updated $info</b></span><br />";
                    if ($name eq 'NumComWorkers' && $new > $old) {
                        ${$name}=$Config{$name} = $old;
                        $ConfigAdd{$name} = $new;
                        return $ret;
                    }
                    if (exists $ModulesUsed{$name}) {
                        $ret = "<span class=\"positive\"><b>*** Updated $info - assp restart is required to activate this change!</b></span><br />";
                        ${$name}=$Config{$name} = $old;
                        $ConfigAdd{$name} = $new;
                        return $ret;
                    }
                    if ($name ne 'ReplaceRecpt' && $Config{$name} ne ${$name} && ! exists $RunTaskNow{$name}) {
                        mlog(0,"error: coding error: config value is not equal config hash in $name - please report to development!");
                        $ret .= "<script type=\"text/javascript\">alert(\"coding error: config value is not equal config hash in $name - please report to development!\");</script>";
                        ${$name}=$Config{$name};
                    }
                    ${$name}=$Config{$name} if ($name eq 'ReplaceRecpt');
                    &syncConfigDetect($name);
                    return $ret;
                }
            } else {
                return "<span class=\"negative\"><b>*** incorrect: '$qs{$name}' $info</b></span><br />
                <script type=\"text/javascript\">alert(\"incorrect '$name' - possibly unchanged.\");</script>";
            }
        } else {
            my $text; $text = "(check returned '$1')" if $qs{$name}=~/$valid/i;
            return "<span class=\"negative\"><b>*** Invalid: '$qs{$name}' $text</b></span><br />
            <script type=\"text/javascript\">alert(\"Invalid '$name' - unchanged.\");</script>";
        }
    }
}
