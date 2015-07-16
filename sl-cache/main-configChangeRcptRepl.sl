#line 1 "sub main::configChangeRcptRepl"
package main; sub configChangeRcptRepl {
 my ($name, $old, $new, $init)=@_;

 mlog(0,"AdminUpdate: recipient replacement updated from '$old' to '$new'") unless $init || $new eq $old;
 $ReplaceRecpt=$Config{ReplaceRecpt}=$new if $WorkerNumber > 0;
 my @new = checkOptionList($new,'ReplaceRecpt',$init);
 if ($new[0] =~ s/^\x00\xff //o) {
     ${$name} = $Config{$name} = $old;
     return ConfigShowError(1,$new[0]);
 }
 return if $WorkerNumber > 0;

 my @check = @new = sort(@new);
 my %ruletable;
 while (@check) {
     my $v = shift @check;
     if ($v =~ /(.*?)\<\=\>(?:R|S|)\<\=\>.*?\<\=\>.*?\<\=\>.*?\<\=\>(?:0|1|2)\<\=\>.*/o) {
         next unless $1;
         $ruletable{$1} = 1;
     }
 }
 $ruletable{'END'} = 1;
 
 my $valid = 0;
 my $invalid = 0;
 my $rulenumber;
 my $rule;
 my %rules;
 my $ret;
 
 while (@new) {
     my $v = shift @new;
     my ($jumpto, $expression, $if);
     if ($v =~ /(.*?)\<\=\>((.*?)\<\=\>.*?\<\=\>.*?\<\=\>.*?\<\=\>(.*?)\<\=\>(.*))/o) {
         $rulenumber = $1;
         $rule = $2;
         $expression = $3;
         $if = $4;
         $jumpto = $5;
     } else {
         $ret .= ConfigShowError(1,"ERROR: general syntax error in recipient replacement rule $v");
         $invalid++;
         next;
     }
     if ($rulenumber eq '') { # rule is disabled
       $ret .= ConfigShowError(1,"ERROR: no rule number - syntax error in recipient replacement rule $v");
       $invalid++;
       next;
     }
     if (! $rule) {  # should never happen - be save
       $ret .= ConfigShowError(1,"ERROR: syntax error in recipient replacement rule $v");
       $invalid++;
       next;
     }
     if ($expression !~ /^(?:R|S|)$/o) {   # simple or re rule
       $ret .= ConfigShowError(0,"warning: ignore rule - invalid entry type '$expression' in recipient replacement rule $v");
       $invalid++;
       next;
     }
     if ($if !~ /^(?:0|1|2)$/o) {   # jump if
       $ret .= ConfigShowError(0,"warning: ignore rule - invalid 'IF' definition '$if' in recipient replacement rule $v");
       $invalid++;
       next;
     }
     if ($rulenumber =~ /END/o) {
       $ret .= ConfigShowError(1,"ERROR: rule number END is not permitted - syntax error in recipient replacement rule $v");
       $invalid++;
       next;
     }
     if ($jumpto && ! exists $ruletable{$jumpto}) {   # the target rule is not available
       $ret .= ConfigShowError(0,"warning: jump target '$jumpto' not found - in recipient replacement rule $v");
     }
     if ($jumpto && $jumpto ne 'END' && $jumpto le $rule) {    # jumping back is worth (possible loop)
       $ret .= ConfigShowError(1,"ERROR: jumping backward to rule '$jumpto' from rule '$rule' is not allowed - jump target error in recipient replacement rule $v");
       $invalid++;
       next;
     }
     if (exists $rules{$rulenumber}) {   # already defined -> replace the rule
       $ret .= ConfigShowError(0,"warning: rule number $rulenumber is already defined with $rules{$rulenumber} - now using entry $v");
       $rules{$rulenumber} = $rule;
       $invalid++;
       next;
     }
     $valid++;
     $rules{$rulenumber} = $rule;
 }
 %RecRepRegex = %rules;
 my $tlit = $init ? 'info: ' : 'AdminUpdate: ';
 if ($valid) {
   $ret .= ConfigShowError(0, $tlit."enabled $valid recipient replacement rules - $invalid invalid rules skipped");
 } else {
   $ret .= ConfigShowError(0, $tlit. "no valid recipient replacement rule found" . ($invalid ? " - $invalid invalid rules skipped" : ''));
 }
 return $ret;
}
