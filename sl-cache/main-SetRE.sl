#line 1 "sub main::SetRE"
package main; sub SetRE {
 use re 'eval';
 my ($var,$r,$f,$desc,$name,$noerror)=@_;
 return if (! $var);
 $name ||= $desc;

 my $noOptimize = 0;
 if (exists $noOptRe{$var}) {
     if ($noOptRe{$var} == 0) {
         $noOptimize = 1;
     }
 }
# my $how = 'default ';
 $desc =~ s/[ *]*$//o;
 $desc =~ s/\<[a-zA-Z0-9]+ .*?\<\/[a-zA-Z0-9]+\>//gio;
 mlog(0,"ERROR: regex variable $var not defined for - '$name <$desc>' - please report")
     if(! defined($$var) && $WorkerNumber == 0);

 if ($CanUseRegexpOptimizer &&
     ! $noOptimize &&
     $optReModule &&
     $r !~ /$neverMatchRE/o &&      # the regex that never matches
     $r =~ /[^\\]\|/so &&                     # no | in regex
     $r !~ s/a(?:ssp)?\\?-do?\\?-n(?:ot)?\\?-o(?:ptimize)?\\?-r(?:egex)?\|?//iso &&  # the special word
     $r !~ /\Q$complexREStart\E/o )           # the complex AND NOT
 {
     my $lenBefore = length($r) + length($f) + 4 + 9;      # (?-xims:(?$f:......))
     if ($WorkerName eq 'startup' && $MaintenanceLog >= 2) {
        print "optimizing regex for $name";
        print ' ' x (35 - length($name));
     }
     eval{
         my $loadRE;
         if (($WorkerNumber != 0) && ($loadRE = &loadexportedRE($name))) {
             $loadRE =~ s/\)$//o if $loadRE =~ s/^\(\?(?:[xims\-\^]*)?\://o;
             $$var = qr/$loadRE/;
         } else {
#             $o->set(debug => $debug);
             my @noOpt;
             my $o = $optReModule->new;
             if ($r =~ /\<\<\<(.*?)\>\>\>/o) { # Regexp::Optimizer is unable to skip optim - so we have to do this
                 while ($r =~ s/\<\<\<(.*?)\>\>\>\|?//o) {
                     push @noOpt, $1;
                 }
                 my ($pre,$post) = $r =~ m{^(\^?).*(\$?)$}o;
                 $r =~ s/^\^?\$?$//;
                 my $noOpt;
                 $$var = '';
                 if (@noOpt) {
                     $noOpt = $pre . join('|',@noOpt) . $post;
                     $$var = qr/(?$f:$noOpt)/;
                     $$var .= '|' if $r;
                 }
                 $$var .= $o->optimize(qr/(?$f:$r)/) if $r;
                 $$var = qr/$$var/ if @noOpt && $r;
             } else {
                 $$var = $o->optimize(qr/(?$f:$r)/);
             }
         }
     };
     if ($@) {
         $RegexError{$name} = 'regex optimization failed - $@ - unoptimized regex is used' if $WorkerNumber == 0;
         mlog(0,"warning: regex optimization failed for '$name - <$desc>' - $@ - try using unoptimized regex") if $WorkerNumber == 0;
         if ($WorkerName eq 'startup' && $MaintenanceLog >= 2) {
             print "[FAILED]\n";
         }
         eval{
             $r =~ s/a(?:ssp)?\\?-do?\\?-n(?:ot)?\\?-o(?:ptimize)?\\?-r(?:egex)?\|?//igos;   # the special word
             $r =~ s/\<\<\<(.*?)\>\>\>/$1/go;   # a single line that should not be optimized
             $$var=qr/(?$f:$r)/;
         };
     } else {
         my $lenAfter = length $$var;
         mlog(0,"info: optimized regex for '$name <$desc>' - length in byte before: ".nN($lenBefore)." - after: ".nN($lenAfter)) if $MaintenanceLog >= 2 && $WorkerNumber == 0;
         if ($WorkerNumber == 0 && $MaintenanceLog >= 2) {
             print "[OK]\n" if $WorkerName eq 'startup';
         }
     }
 } else {
     eval{
         $r =~ s/a(?:ssp)?\\?-do?\\?-n(?:ot)?\\?-o(?:ptimize)?\\?-r(?:egex)?\|?//igso;  # a-d-n-o-r
         $r =~ s/\<\<\<(.*?)\>\>\>/$1/go;      # a single line that should not be optimized

         # '?|' = alternativ gouping capture starting every time by $1
         # only available in 5.10 or above  and needed for complexRE
         # but buggy in 5.10 ([RT #59734]) - fixed in 5.12
         # so it is only used if complexRE is defined
         $$var = ($r !~ /\Q$complexREStart\E/o) ? qr/(?$f:$r)/ : qr/(?$f:(?|$r))/;
     };
 }
 if ($@) {
     $RegexError{$name} = 'error in regular expression' if $WorkerNumber == 0;
     mlog(0,"regular expression error in '$r' for '$name <$desc>': $@") unless $noerror;
     $r = $neverMatch; # regexp that never matches
     $$var=qr/(?$f:$r)/;
     return 0;
 } else {
     delete $RegexError{$name} if $WorkerNumber == 0;
     exportOptRE($var,$name) if ($WorkerNumber == 0);
 }
 return 1;
}
