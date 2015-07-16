#line 1 "sub main::getRRData"
package main; sub getRRData {
    my ($dom, $type) = @_;
    return unless ($dom && $type);
    return getRRA($dom, $type) if uc($type) eq 'A' or uc($type) eq 'AAAA';
    my $gotname;
    my $gottype;
    my $gotdata;
    eval {
      my $res = queryDNS($dom,$type);
      my @data;
      my @answers;
      if (ref($res) && (@answers = $res->answer)) {
          @answers = map{Net::DNS::RR->new($_->string)} @answers;
          if (lc($type) eq 'txt') {
              for my $RR (@answers) {
                  next if lc($RR->type) ne lc($type);
                  $gotname ||= $RR->name;
                  $gottype ||= $RR->type;
                  push @data, $RR->char_str_list;
              }
              $gotdata = join('',@data);       # return all TXT entries joined
          } else {
              for my $RR (@answers) {
                  next if (lc($RR->type) ne lc($type) && uc($type) ne 'ANY');
                  $gotname ||= $RR->name;
                  $gottype ||= $RR->type;
                  push @data, $RR->rdatastr;
              }
              if (@data) {
                  if (uc $type eq 'PTR') {
                      $gotdata = $data[0];  # return only the first PTR
                      if (@data > 1 && $DoInvalidPTR) {   # search for the first not invalid PTR if multiple were found
                          for my $r (@data) {
                              next if $r =~ /$invalidPTRReRE/ && $r !~ /$validPTRReRE/;
                              $gotdata = $r;
                              last;
                          }
                      }
                      $gotdata =~ s/[\.\s]+$//o;
                  } else {
                      $gotdata = join("\n",@data); # return NS and SOA ... joined with LF
                  }
              }
          }
      }
    };
    if ($@) {
        mlog(0,"warning: $@ - for DNS query on '$dom','$type'")
          if ($@ !~ /SIGCONT handler|SWASHNEW/o);
        return;
    }
    return $gotdata || 0 if uc($type) eq 'NS' || uc($type) eq 'ANY';
    return if lc($gotname) ne lc($dom) && uc($type) ne 'PTR';
    return if lc($gottype) ne lc($type);
    return $gotdata;
}
