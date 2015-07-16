#line 1 "sub main::initBDBEnv"
package main; sub initBDBEnv {
  my ($hash,$file) = @_;
  if ($DBusedDriver eq 'BerkeleyDB' && $CanUseBerkeleyDB) {
      my %bdbo = ();
      %bdbo = eval('('.$DBOption.')') if $DBOption;
      mlog(0,"info: DBOption: $DBOption") if (($debug || $DataBaseDebug) && $WorkerNumber == 0);
      foreach (keys %bdbo) {
          mlog(0,"info: defined BerkeleyOption: $_ = $bdbo{$_}") if (($debug || $DataBaseDebug) && $WorkerNumber == 0);
      }
      my %userenv = ();
      if ($bdbo{-Env}) {
          %userenv = %{$bdbo{-Env}} if (ref $bdbo{-Env} && $bdbo{-Env} =~ /HASH/o);
          %userenv = @{$bdbo{-Env}} if (ref $bdbo{-Env} && $bdbo{-Env} =~ /ARRAY/o);
          $bdbcache = $userenv{'-Cachesize'} if $userenv{'-Cachesize'};
          delete $userenv{'-Cachesize'};
          delete $bdbo{-Env};
      }
      $bdbcache = $bdbo{'-Cachesize'} unless $bdbcache;
      delete $bdbo{'-Cachesize'};
      $userenv{'-Cachesize'} = $bdbcache;
      eval('$bdbo{-Flags} = DB_CREATE;');
      $bdbo{'-Env'} = &createBDBEnv($hash, \%userenv);
      delete $bdbo{'-Env'} unless $bdbo{'-Env'};
      return %bdbo;
  }
}
