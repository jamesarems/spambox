#line 1 "sub main::resendError"
package main; sub resendError {
     my ($file,$message) = @_;
    
     if ($eF->( $file)) {
          $ResendFile{$file} = 0 if (! exists $ResendFile{$file});
          if (++$ResendFile{$file} > 10) {
              my $act = 'modified';
              if ($ResendFile{$file} == 99) {
                  mlog(0,"*x*error: send $file aborted, because it is infected by a virus") if $MaintenanceLog;
                  $act = 'virus';
              } else {
                  mlog(0,"*x*error: send $file aborted after $ResendFile{$file} unsuccessful tries") if $MaintenanceLog;
              }
              delete $ResendFile{$file};
              $file =~ s/\\/\//go;
              if ($eF->( $file.'.err')) {
                  mlog(0,"*x*warning: unable to delete $file.err - $!") unless ($unlink->($file.'.err')) ;
              }
              if ($act ne 'virus') {
                  mlog(0,"*x*warning: unable to rename $file to $file.err - $!") unless ($rename->($file,$file.'.err'));
              }
              if ($open->(my $MF,'>',$file.'.err.'.$act)) {
                 $MF->binmode;
                 $MF->print($$message);
                 $MF->close;
                 mlog(0,"*x*warning: the modified content of file $file was stored in to file $file.err.$act") if $MaintenanceLog;
              }
          }
      } else {
          delete $ResendFile{$file};
      }
}
