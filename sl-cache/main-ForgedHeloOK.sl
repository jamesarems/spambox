#line 1 "sub main::ForgedHeloOK"
package main; sub ForgedHeloOK {
  my $fh = shift;
  return 1 if ! $DoFakedLocalHelo;
  return ForgedHeloOK_Run($fh);
}
