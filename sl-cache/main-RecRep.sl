#line 1 "sub main::RecRep"
package main; sub RecRep {
  my ($toregex,$replregex,$sendregex,$recpt,$sender,$rnum) = @_;
  my @retval;
  my $cmpl_error;
  $retval[0] = "result";

  $cmpl_error = RecRepSetRE('TO_RE',$toregex);
  push (@retval, $cmpl_error) if ($cmpl_error);
  $cmpl_error = RecRepSetRE('RP_RE',$replregex);
  push (@retval, $cmpl_error) if ($cmpl_error);
  $cmpl_error = RecRepSetRE('SE_RE',$sendregex);
  push (@retval, $cmpl_error) if ($cmpl_error);

  if ($sender =~ /$SE_RE/i && $recpt =~ /$TO_RE/i) {

    push (@retval, "$rnum  |\$1=$1|\$2=$2|\$3=$3|\$4=$4|\$5=$5|\$6=$6|\$7=$7|\$8=$8|\$9=$9|");
    my $d1 = $1;my $d2 = $2;my $d3 = $3;
    my $d4 = $4;my $d5 = $5;my $d6 = $6;
    my $d7 = $7;my $d8 = $8;my $d9 = $9;


    $replregex =~ s/\$1/$d1/g;
    $replregex =~ s/\$2/$d2/g;
    $replregex =~ s/\$3/$d3/g;
    $replregex =~ s/\$4/$d4/g;
    $replregex =~ s/\$5/$d5/g;
    $replregex =~ s/\$6/$d6/g;
    $replregex =~ s/\$7/$d7/g;
    $replregex =~ s/\$8/$d8/g;
    $replregex =~ s/\$9/$d9/g;
    if (wantarray){
      $retval[0] = $replregex;
      push(@retval,'1');
      return @retval;
    } else {
      return $replregex;
    }
  } else {
    if (wantarray){
      $retval[0] = $recpt;
      push(@retval,'0');
      return @retval;
    } else {
      return $recpt;
    }
  }
}
