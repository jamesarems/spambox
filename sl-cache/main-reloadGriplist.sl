#line 1 "sub main::reloadGriplist"
package main; sub reloadGriplist {
   if ($griplist) {
        if ($GriplistDriver eq 'orderedtie') {
            if (! $GriplistObj) {
                $GriplistObj=tie %Griplist,$GriplistDriver,$GriplistFile;
                $GriplistObj->resetCache();
                my $r = loadHashFromFile("$base/$griplist", $GriplistObj->{cache}) || 'no';
                mlog(0,"info: Griplist has $r records") if $MaintenanceLog >= 2;
                $GriplistObj->{max} = 999999999999;
                $GriplistObj->{bin} = 0;
            }
            if (ftime($GriplistObj->{fn}) != $GriplistObj->{age}) {
                $GriplistObj->resetCache();
                my $r = loadHashFromFile("$base/$griplist", $GriplistObj->{cache}) || 'no';
                mlog(0,"info: Griplist has $r records") if $MaintenanceLog >= 2;
            }
        } elsif ($GriplistDriver eq 'BerkeleyDB::Hash' && $useDB4griplist && ! $GriplistObj) {
            my $file = "$base/$griplist";
            my $env = &createBDBEnv('Griplist');
            &tieToBDB('Griplist', "$file.bdb", $env);
        }
    }
}
