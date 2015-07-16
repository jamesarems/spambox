#line 1 "sub main::RecRepSetRE"
package main; sub RecRepSetRE {
 use re 'eval';
 my ($var,$r)=@_;
 eval{$$var=qr/(?i)$r/;1;} or return $@;
 return;
}
