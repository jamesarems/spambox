#line 1 "sub main::_tree2re"
package main; sub _tree2re {
   my ( $tree ) = @_;
   no warnings qw(recursion);
   return
       defined $tree->{code}       ? ( "(?{'$tree->{code}'})"            )  # Match
       : $tree->{0} && $tree->{1}  ? ( '(?>0', _tree2re($tree->{0}),
                                         '|1', _tree2re($tree->{1}), ')' )  # Choice
       : $tree->{0}                ? (    '0', _tree2re($tree->{0})      )  # Literal, no choice
       : $tree->{1}                ? (    '1', _tree2re($tree->{1})      )  # Literal, no choice
       : die 'Internal error: failed to create a regexp from the supplied IP ranges'
       ;
}
