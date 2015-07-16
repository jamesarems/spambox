#line 1 "sub main::optionFilesReload"
package main; sub optionFilesReload {
 # check if options files have been updated and need to be re-read
    for my $idx (0...$#PossibleOptionFiles) {
        my $f = $PossibleOptionFiles[$idx];
        if($f->[0] ne 'spamboxCfg' or ($f->[0] eq 'spamboxCfg' && $AutoReloadCfg)) {
            if ($Config{$f->[0]}=~/^ *file: *(.+)/io && fileUpdated($1,$f->[0]) ) {
                $f->[2]->($f->[0],$Config{$f->[0]},$Config{$f->[0]},'',$f->[1]);
                &syncConfigDetect($f->[0]);
            }
        }
    }
}
